module Jtb
  class Price
    JTB_CURRENCY = 'JPY'

    attr_reader :quotation, :params

    def initialize(params)
      @params = params
      @quotation = Quotation.new(@params.merge(currency: JTB_CURRENCY))
    end

    def quote(response)
      total = extract_total_from response

      if total
        quotation.total     = total
        quotation.available = true
        Result.new(quotation)
      else
        Result.error(:unavailable_property, params.to_s)
      end
    end

    private

    def parse(response)
      availabilities = response.dig(:ga_hotel_avail_rs, :room_stays, :room_stay)
      return unless availabilities

      availabilities.map do |room_stay|
        next unless room_stay[:@availability_status] == 'OK'
        {
            price:      room_stay[:room_rates][:room_rate][:total][:@amount_after_tax],
            start_date: room_stay[:time_span][:@start],
            end_date:   room_stay[:time_span][:@end],
            rate_plan:  room_stay[:rate_plans][:rate_plan][:@rate_plan_id],
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