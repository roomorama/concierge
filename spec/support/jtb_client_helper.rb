module Support
  module JTBClientHelper

    def build_quote_response(availabilities)
      {
        ga_hotel_avail_rs: {
          room_stays: {
            room_stay: availabilities
          }
        }
      }
    end

    def availability(attributes)
      {
        rate_plans:           { rate_plan: { :@rate_plan_id => attributes[:rate_plan_id] } },
        time_span:            { :@start => attributes[:date], :@end => attributes[:date] },
        room_rates:           { room_rate: { total: { :@amount_after_tax => attributes[:price] } } },
        room_types:           { room_type: { occupancy: { :@max_occupancy => attributes[:occupancy] } } },
        :@availability_status => attributes[:status]
      }
    end

  end
end
