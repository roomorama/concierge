module Jtb
  class Client
    JTB_CURRENCY = 'JPY'

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def quote(params)
      response = api.quote_price(params)
      total    = extract_total_from(response)
      if total
        Quotation.new(params.to_h.merge(currency: JTB_CURRENCY, total: total))
      else
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

    private

    def api
      @api ||= Jtb::Api.new(credentials)
    end

    def parse(response)
      availabilities = response.dig(:ga_hotel_avail_rs, :room_stays, :room_stay)
      return unless availabilities

      availabilities.map do |room_stay|
        next unless room_stay[:@availability_status] == 'OK'
        {
            price:               room_stay[:room_rates][:room_rate][:total][:@amount_after_tax],
            start_date:          room_stay[:time_span][:@start],
            end_date:            room_stay[:time_span][:@end],
            rate_plan:           room_stay[:rate_plans][:rate_plan][:@rate_plan_id],
        }
      end.compact
    end

    def extract_total_from(response)
      rates = parse response
      return unless rates
      cheapest_rate = rates.min_by { |rate| rate[:price].to_i }
      cheapest_rate[:price]
    end

  end
end
