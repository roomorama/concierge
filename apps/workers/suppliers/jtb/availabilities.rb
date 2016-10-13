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

            fill_property_calendar(calendar, units)
          end
        end
        synchronisation.finish!
      end
    end

    private

    def fill_property_calendar(calendar, units)
      units.each do |unit|
        calendar_result = mapper.build(unit['identifier'])
        # if at least one unit's calendar failed fail all the property's calendar
        return calendar_result unless calendar_result.success?

        calendar.add_unit(calendar_result.value)
      end

      Result.new(calendar)
    end

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
  end
end

# listen supplier worker
Concierge::Announcer.on('availabilities.JTB') do |host, args|
  Workers::Suppliers::JTB::Availabilities.new(host).perform
  Result.new({})
end