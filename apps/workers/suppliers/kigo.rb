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

  def perform
    result = importer.fetch_properties
    if result.success?
      properties = result.value
      properties.each do |property|
        # payload validation
        next if property['PROP_PROVIDER'].nil?
        id     = property['PROP_ID']
        result = importer.fetch_data(id)
        # result_price = importer.fetch_prices(id)

        if result.success?
          mapper.prepare(result.value)
        else
          synchronisation.failed!
          message = "Failed to perform the `#fetch_data` operation, with identifier: `#{id}`"
          announce_error(message, result)
          result
        end
      end
      synchronisation.finish!
    else
      message = "Failed to perform the `#fetch_properties` operation"
      announce_error(message, result)
    end
  end

  private

  def filter(properties)
    properties.select do |property|
      provider = property['PROP_PROVIDER']
      provider && (ids.include?(provider['RA_ID'] || ids.include?(provider['OWNER_ID'])))
    end

  end


  def importer
    @importer ||= Kigo::Importer.new(credentials, request_handler)
  end

  def request_handler
    Kigo::Request.new(credentials)
  end

  def mapper
    Kigo::Mappers::Property.new(references: importer.fetch_references)
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
