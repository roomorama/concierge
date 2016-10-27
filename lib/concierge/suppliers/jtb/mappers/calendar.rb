module JTB
  module Mappers
    # +JTB::Mappers::Calendar+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object
    # for property from data getting from JTB.
    class Calendar
      attr_reader :property

      def initialize(property)
        @property  = property
      end

      def build
        calendar = Roomorama::Calendar.new(property.identifier)
        units = Array(property.data['units'])

        fill_property_calendar(calendar, units)
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

      def mapper
        @mapper ||= ::JTB::Mappers::UnitCalendar.new
      end
    end
  end
end
