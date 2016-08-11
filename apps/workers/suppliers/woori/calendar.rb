module Workers::Suppliers::Woori
  class Calendar
    attr_reader :synchronisation, :host

    def initialize(host)
      @host = host
      @sync = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      synced_properties.each do |property|
        sync.start(property.identifier) do
          Concierge.context.disable!

          calendar_result = importer.fetch_calendar(property)

          if calendar_result.success?
            calendar_result.value
          else
            announce_calendar_fetch_error(unit, calendar_result)
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

    def mapper
      @mapper ||= Woori::Mappers::Calendar.new
    end

    def synced_properties
      PropertyRepository.from_host(host)
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
        supplier:    ::Woori::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def announce_calendar_fetch_error(unit, result)
      message = "Failed to perform the `fetch unit calendar` operation for unit with id #{unit.identifier}"
      announce_error(message, result)
    end
  end
end

Concierge::Announcer.on("calendar.Woori") do |host|
  Workers::Suppliers::Woori::Calendar.new(host).perform
end
