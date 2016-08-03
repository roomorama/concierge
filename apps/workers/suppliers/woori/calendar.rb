module Workers::Suppliers
  class Woori::Calendar
    def initialize(host)
      @host = host
      @sync = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      synced_properties.each do |property|
        property.data["units"].each do |unit|

          sync.start(unit["identifier"]) do
            Concierge.context.disable!

            calendar_result = fetch_unit_calendar(unit)

            if calendar_result.success?
              calendar_result.value
            else
              announce_calendar_fetch_error(unit, calendar_result)
              calendar_result
            end
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

    def fetch_unit_rates(unit)
      retries ||= 3
      result = importer.fetch_unit_rates(unit.identifier)

      if result.success?
        result
      else
        raise UnitRatesFetchError
      end
    rescue UnitRatesFetchError
      if (retries -= 1) > 0
        retry
      else
        result
      end
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
