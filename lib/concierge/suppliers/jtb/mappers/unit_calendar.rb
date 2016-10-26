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
        entries = build_entries(unit_id)

        return entries unless entries.success?

        calendar = Roomorama::Calendar.new(unit_id).tap do |calendar|
          entries.value.each do |entry|
            calendar.add(entry)
          end
        end

        Result.new(calendar)
      end

      private

      def build_entries(unit_id)
        u_id = JTB::UnitId.from_roomorama_unit_id(unit_id)
        room = JTB::Repositories::RoomTypeRepository.by_code(u_id.room_code)

        # Room not found. Next metadata sync will remove the unit.
        return Result.error(:unknown_room, "Can not sync calendar for unknown unit #{unit_id}") unless room

        rate_plans = JTB::Repositories::RatePlanRepository.room_rate_plans(room)

        from = Date.today
        to = from + Workers::Suppliers::JTB::Metadata::PERIOD_SYNC

        # All rate plans have the same availabilities for a given unit
        # so we can take only first one
        stocks = JTB::Repositories::RoomStockRepository.availabilities(rate_plans.first&.rate_plan_id, from, to)
        entries = stocks.map do |stock|
          available = false
          nightly_rate = 0
          if available_stock?(stock)
            min_price = JTB::Repositories::RoomPriceRepository.room_min_price_for_date(room, rate_plans, stock.service_date)
            if min_price
              available = true
              nightly_rate = min_price
            end
          end
          Roomorama::Calendar::Entry.new(
            date: stock.service_date,
            available: available,
            nightly_rate: nightly_rate
          )
        end
        Result.new(entries)
      end

      def available_stock?(stock)
        # Sale status: 0 - On sale, 1 - Not on sale (Requests are not accepted)
        stock.number_of_units > 0 && stock.sale_status == '0'
      end
    end
  end
end
