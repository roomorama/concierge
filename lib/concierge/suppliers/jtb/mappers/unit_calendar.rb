module JTB
  module Mappers
    # +JTB::Mappers::UnitCalendar+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object
    # for unit from data getting from JTB.
    class UnitCalendar

      # Maps JTB data to +Roomorama::Calendar+ for unit
      # Arguments
      #
      #   * +unit_id+ [String] roomorama unit id of JTB room
      # Returns +Roomorama::Calendar+
      def build(unit_id)
        Roomorama::Calendar.new(unit_id).tap do |calendar|
          build_entries(unit_id).each do |entry|
            calendar.add(entry)
          end
        end
      end

      private

      def build_entries(unit_id)
        u_id = JTB::UnitId.from_roomorama_unit_id(unit_id)
        room = JTB::Repositories::RoomTypeRepository.by_code(u_id.room_code)

        rate_plans = JTB::Repositories::RatePlanRepository.room_rate_plans(room)

        from = Date.today
        to = from + Workers::Suppliers::JTB::Metadata::PERIOD_SYNC
        stocks = JTB::Repositories::RoomStockRepository.availabilities(rate_plans, from, to)

        stocks.map do |stock|
          if stock.number_of_units <= 0 || stock.sale_status == '0'
            available = false
            nightly_rate = 0
          else
            min_price = JTB::Repositories::RoomPriceRepository.room_min_price(room, rate_plans, stock.service_date)
            if min_price
              available = true
              nightly_rate = min_price
            else
              available = false
              nightly_rate = 0
            end
          end
          Roomorama::Calendar::Entry.new(
            date: stock.service_date,
            available: available,
            nightly_rate: nightly_rate
          )
        end
      end
    end
  end
end
