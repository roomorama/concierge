module Workers::Suppliers::Kigo
  # +Workers::Suppliers::Kigo::Legacy+
  #
  # Performs synchronisation with supplier
  class Legacy

    CACHE_PREFIX  = 'metadata.kigo_legacy'

    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    # for the fetching a property data performing process has to make two calls
    #
    #   * fetch_data   - performs fetching base property data
    #   * fetch_prices - returns property pricing setup. (Uses for deposit, additional price ...)
    #
    # uses caching for properties list to avoid the same call for different hosts
    def perform
      references = with_cache('references') { importer.fetch_references }
      unless references.success?
        message = 'Failed to perform `#fetch_references`'
        announce_error(message, references)
        return
      end

      mapper = Kigo::Mappers::Property.new(references.value, resolver: mapper_resolver)
      result = with_cache('list') { importer.fetch_properties }
      if result.success?
        properties = host_properties(result.value)

        return if properties.empty?

        if host_deactivated?(properties.first)
          delete_host! and return
        end

        properties.each do |property|
          id = property['PROP_ID']
          synchronisation.start(id) do
            data_result = importer.fetch_data(id)

            next data_result unless data_result.success?

            # in this case KigoLegacy PROP_INSTANT_BOOK=true means +false+.
            # In the next version (Kigo) they have fixed it
            next non_ib_result if data_result.value['PROP_INSTANT_BOOK']

            price_result = importer.fetch_prices(id)

            next price_result unless price_result.success?

            mapper.prepare(data_result.value, price_result.value['PRICING'])
          end
        end
        synchronisation.finish!
      else
        message = "Failed to perform the `#fetch_properties` operation"
        announce_error(message, result)
      end
    end

    private

    def host_properties(properties)
      properties.select do |property|
        wrapped_payload(property).get("PROP_PROVIDER.RA_ID") == host.identifier.to_i
      end
    end

    def host_deactivated?(property)
      Kigo::HostCheck.new(property['PROP_ID'], request_handler: request_handler).deactivated?
    end

    def delete_host!
      HostRepository.delete(host)
    end

    def wrapped_payload(payload)
      Concierge::SafeAccessHash.new(payload)
    end

    def importer
      @importer ||= Kigo::Importer.new(credentials, request_handler)
    end

    def mapper_resolver
      Kigo::Mappers::LegacyResolver.new
    end

    def request_handler
      Kigo::LegacyRequest.new(credentials, timeout: 40)
    end

    def credentials
      Concierge::Credentials.for(supplier_name)
    end

    def supplier_name
      Kigo::Legacy::SUPPLIER_NAME
    end

    def non_ib_result
      Result.error(:non_ib_property)
    end

    def announce_error(message, result)
      message = {
        label:     'Synchronisation Failure',
        message:   message,
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    supplier_name,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def with_cache(key)
      freshness = 60 * 60 * 3 # 3 hours
      cache.fetch(key, freshness: freshness, serializer: json_serializer) { yield }
    end

    def json_serializer
      @serializer ||= Concierge::Cache::Serializers::JSON.new
    end

    def cache
      @_cache ||= Concierge::Cache.new(namespace: CACHE_PREFIX)
    end
  end
end

# listen supplier worker
Concierge::Announcer.on("metadata.#{Kigo::Legacy::SUPPLIER_NAME}") do |host|
  Workers::Suppliers::Kigo::Legacy.new(host).perform
end
