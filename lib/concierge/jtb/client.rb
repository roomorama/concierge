module Jtb
  class Client
    JTB_CURRENCY = 'JPY'

    def quote(params)
      response = api.quote_price(params)
      rates    = prepare response
      total    = extract_total_from(rates)
      Quotation.new(params.to_h.merge(currency: JTB_CURRENCY, total: total))
    end

    private

    def credentials
    end

    def api
      @api ||= Jtb::Api.new(credentials)
    end

    def prepare(response)
      availabilities = response.dig(:ga_hotel_avail_rs, :room_stays, :room_stay)
      return unless availabilities

      availabilities.map do |room_stay|
        {
            price:               room_stay[:room_rates][:room_rate][:total][:@amount_after_tax],
            start_date:          room_stay[:time_span][:@start],
            end_date:            room_stay[:time_span][:@end],
            rate_plan:           room_stay[:rate_plans][:rate_plan][:@rate_plan_id],
            availability_status: room_stay[:@availability_status]
        }
      end
    end

    def extract_total_from(rates)
      cheapest_rate = rates.min_by { |rate| rate[:price] }
      cheapest_rate[:price]
    end

  end
end
