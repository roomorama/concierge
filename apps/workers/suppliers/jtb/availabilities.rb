module Workers::Suppliers::JTB
  # +Workers::Suppliers::JTB::Availabilities+
  #
  # Performs properties availabilities synchronisation with supplier
  class Availabilities
    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      result = synchronisation.new_context do
        actualizer.actualize
      end

      if result.success?
        properties = synced_properties

        properties.each do |property|

          synchronisation.start(property.identifier) do

            calendar = Roomorama::Calendar.new(property.identifier)
            units = Array(property.data['units'])
            units.each do |unit|
              calendar_result = mapper.build(unit['identifier'])
              return calendar_result unless calendar_result.success?
              calendar.add_unit(calendar_result.value)
            end
            Result.new(calendar)
          end
        end
        synchronisation.finish!
      end
    end

    private

    def actualizer
      @actualizer ||= ::JTB::Sync::Actualizer.new(credentials)
    end

    def mapper
      @mapper ||= ::JTB::Mappers::UnitCalendar.new
    end

    def credentials
      Concierge::Credentials.for(JTB::Client::SUPPLIER_NAME)
    end

    def synced_properties
      PropertyRepository.from_host(host)
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

    def announce_error(message, result)
      augment_context_error(message)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    JTB::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('availabilities.JTB') do |host, args|
  Workers::Suppliers::JTB::Availabilities.new(host).perform
  Result.new({})
end