module Workers::Suppliers::JTB
  # +Workers::Suppliers::JTB::Availabilities+
  #
  # Performs availabilities synchronisation for given property
  class Availabilities
    attr_reader :synchronisation, :host, :property

    def initialize(host, property)
      @host            = host
      @property        = property
      @synchronisation = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      synchronisation.start(property.identifier) do

        calendar = Roomorama::Calendar.new(property.identifier)
        units = Array(property.data['units'])

        fill_property_calendar(calendar, units)
      end
      synchronisation.finish!
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
  end
end
