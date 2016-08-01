# +Workers::Suppliers::Kigo+
#
# Performs synchronisation with supplier
class Workers::Suppliers::Kigo

  SUPPLIER_NAME = 'Kigo'

  attr_reader :synchronisation, :host

  def initialize(host)
    @host            = host
    @synchronisation = Workers::PropertySynchronisation.new(host)
  end

  # for the fetching a property data performing process has to make two calls
  #
  #   * fetch_data   - performs fetching base property data
  #   * fetch_prices - returns property pricing setup. (Uses for deposit, additional price ...)
  def perform
    result = importer.fetch_properties
    if result.success?
      properties = result.value
      properties.each do |property|
        next if property['PROP_PROVIDER'].nil?
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

end

# listen supplier worker
Concierge::Announcer.on("metadata.Kigo") do |host|
  Workers::Suppliers::Kigo.new(host).perform
end
