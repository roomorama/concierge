module Workers::Suppliers::Ciirus
  # +Workers::Suppliers::Ciirus::Calendar+
  #
  # Performs properties availabilities synchronisation with supplier
  class Calendar
    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      identifiers = @synchronisation.all_identifiers

      identifiers.each do |property_id|
        synchronisation.start(property_id) do

          result = importer.fetch_rates(property_id)
          if result.success?
            rates = result.value
          else
            message = "Failed to fetch rates for property `#{property_id}`"
            announce_error(message, result)
            return result
          end


          result = importer.fetch_reservations(property_id)
          if result.success?
            reservations = result.value
          else
            message = "Failed to fetch availabilities for property `#{property_id}`"
            announce_error(message, result)
            return result
          end

          roomorama_calendar = mapper.build(property_id, rates, reservations)

          Result.new(roomorama_calendar)
        end
      end
      synchronisation.finish!
    end

    private

    def mapper
      @mapper ||= ::Ciirus::Mappers::RoomoramaCalendar.new
    end

    def importer
      @importer ||= ::Ciirus::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(Ciirus::Client::SUPPLIER_NAME)
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
        supplier:    Ciirus::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('calendar.Ciirus') do |host|
  Workers::Suppliers::Ciirus::Calendar.new(host).perform
end
