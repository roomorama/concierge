module Workers::Suppliers::Woori
  # +Workers::Suppliers::Woori::Availabilities+
  #
  # Performs properties availabilities synchronisation with supplier
  class Availabilities
    attr_reader :sync, :host

    def initialize(host)
      @host = host
      @sync = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      synced_properties.each do |property|
        sync.start(property.identifier) do
          calendar_result = importer.fetch_calendar(property)

          if calendar_result.success?
            calendar_result
          else
            augment_calendar_fetch_error(property)
            calendar_result
          end
        end
      end
    end

    private
    def importer
      @importer ||= ::Woori::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(::Woori::Client::SUPPLIER_NAME)
    end

    def synced_properties
      PropertyRepository.from_host(host)
    end

    def augment_calendar_fetch_error(property)
      message = "Failed to perform the `fetch_calendar` operation for property with id `#{property.identifier}`"
      augment_context_error(message)
    end

    def augment_context_error(message)
      message = {
        label: 'Synchronisation Failure',
        message: message,
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)
    end
  end
end

Concierge::Announcer.on("availabilities.Woori") do |host, args|
  Workers::Suppliers::Woori::Availabilities.new(host).perform
  Result.new({})
end
