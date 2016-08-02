# +Workers::Suppliers::Kigo+
#
# Performs synchronisation with supplier
class Workers::Suppliers::Kigo

  SUPPLIER_NAME = 'Kigo'
  CACHE_PREFIX  = 'metadata.kigo'

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
    result = with_cache('list') { importer.fetch_properties }
    if result.success?
      properties = host_properties(result.value)

      return if properties.empty?

      properties.each do |property|
        id = property['PROP_ID']
        data_result = importer.fetch_data(id)

        unless data_result.success?
          message = "Failed to perform the `#fetch_data` operation, with identifier: `#{id}`"
          announce_error(message, data_result)
          next data_result
        end
        # TODO: mark non instant booking property and skip it for the next sync process
        next unless data_result.value['PROP_INSTANT_BOOK']

        synchronisation.start(id) do
          price_result = importer.fetch_prices(id)

          unless price_result.success?
            synchronisation.failed!
            message = "Failed to perform the `#fetch_prices` operation, with identifier: `#{id}`"
            announce_error(message, price_result)
            next price_result
          end
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
      property['PROP_PROVIDER'] && property['PROP_PROVIDER']['RA_ID'] == host.identifier.to_i
    end
  end

  def importer
    @importer ||= Kigo::Importer.new(credentials, request_handler)
  end

  def request_handler
    Kigo::Request.new(credentials)
  end

  def mapper
    Kigo::Mappers::Property.new(importer.fetch_references)
  end

  def credentials
    Concierge::Credentials.for(SUPPLIER_NAME)
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
      supplier:    SUPPLIER_NAME,
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

# listen supplier worker
Concierge::Announcer.on("metadata.Kigo") do |host|
  Workers::Suppliers::Kigo.new(host).perform
end
