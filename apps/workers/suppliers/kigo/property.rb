module Workers::Suppliers::Kigo
  # +Workers::Suppliers::Kigo::Property+
  #
  # Performs synchronisation with supplier
  class Property

    CACHE_PREFIX = 'metadata.kigo'

    attr_reader :synchronisation, :host, :property_identifier

    def initialize(property_identifier)
      @property_identifier = property_identifier
    end

    # for the fetching a property data performing process has to make two calls
    #
    #   * fetch_data   - performs fetching base property data
    #   * fetch_prices - returns property pricing setup. (Uses for deposit, additional price ...)
    #
    # uses caching for properties list to avoid the same call for different hosts
    def perform
      set_new_context!
      property_fetch = importer.fetch_data(property_identifier)

      if !property_fetch.success? && !should_disable(property_fetch)
        # This call is already retried 8 times on 429 (see lib/concierge/suppliers/kigo/request),
        # we stop the process on further 429 or other errors.
        return property_fetch
      end

      return Result.error(:no_host) unless host_of(property_fetch)  # not an error, just that this Kigo host is not registered in Concierge yet.
      if !valid_payload?(property_fetch.value) && !should_disable(property_fetch)
        return Result.error(:unsupported_property)
      end

      @synchronisation = Workers::PropertySynchronisation.new(host)
      synchronisation.skip_purge!  # don't purge this host's other properties

      synchronisation.start(property_identifier) do
        next Result.new(inactive_property) if should_disable(property_fetch)

        price_fetch = importer.fetch_prices(property_identifier)
        next price_fetch unless price_fetch.success?

        references_fetch = with_cache('references') { importer.fetch_references }
        next references_fetch unless references_fetch.success?
        mapper = Kigo::Mappers::Property.new(references_fetch.value, resolver: mapper_resolver)

        mapper.prepare(property_fetch.value, price_fetch.value['PRICING'])
      end
      synchronisation.finish!
      return Result.new(true)
    end

    private

    def should_disable(property_fetch)
      property_fetch.error.code == :record_not_found
    end

    def inactive_property
      Roomorama::Property.new(property_identifier).tap do |property|
        property.disabled = true
      end
    end

    def set_new_context!
      Concierge.context = Concierge::Context.new(type: "batch")

      message = Concierge::Context::Message.new(
        label:     "Kigo property sync",
        message:   "Started single property sync for `#{supplier_name}`",
        backtrace: caller
      )

      Concierge.context.augment(message)
    end

    def wrapped_payload(payload)
      Concierge::SafeAccessHash.new(payload)
    end

    def importer
      @importer ||= Kigo::Importer.new(credentials, request_handler)
    end

    def request_handler
      Kigo::Request.new(credentials, timeout: 40)
    end

    def credentials
      Concierge::Credentials.for(supplier_name)
    end

    def supplier_name
      Kigo::Client::SUPPLIER_NAME
    end

    def supplier
      @supplier ||= SupplierRepository.named(supplier_name)
    end

    def valid_payload?(payload)
      Kigo::PayloadValidation.new(payload).valid?
    end

    def mapper_resolver
      Kigo::Mappers::Resolver.new
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

    def host_of(property_fetch)
      @host ||= begin
        if property_fetch.success?
          identifier = wrapped_payload(property_fetch.value).get("PROP_PROVIDER.RA_ID").to_s
          HostRepository.from_supplier(supplier).identified_by(identifier).first
        else
          # Get the host from previously persisted property record
          persisted_property = PropertyRepository.from_supplier(supplier).
            identified_by(property_identifier).first
          HostRepository.find persisted_property&.host_id
        end
      end
    end
  end
end
