module Workers::Suppliers
  # +Workers::Suppliers::Kigo+
  #
  # Performs synchronisation with supplier
  class Kigo
    SUPPLIER_NAME = 'Kigo'

    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::Synchronisation.new(host)
    end

    def perform
      result = importer.fetch_properties
      if result.success?
        properties = result.value
        properties.each do |property|
          id = property['PROP_ID']
          synchronisation.start(id) do
            result = importer.fetch_data(id)
            if result.success?
              mapper.prepare(result.value)
            else
              synchronisation.failed!
              message = "Failed to perform the `#fetch_data` operation, with identifier: `#{id}`"
              announce_error(message, result)
            end
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
      @importer ||= ::Kigo::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(SUPPLIER_NAME)
    end

    def announce_error(message, result)
      message = {
        label: 'Synchronisation Failure',
        message: message,
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
end

# listen supplier worker
Concierge::Announcer.on("sync.Kigo") do |host|
  Workers::Suppliers::Kigo.new(host).perform
end
