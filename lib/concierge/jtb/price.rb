module Jtb
  class Price
    JTB_CURRENCY = 'JPY'

    attr_reader :quotation, :params

    def initialize(params)
      @params             = params
      @quotation          = Quotation.new(@params.to_h)
      @quotation.currency = JTB_CURRENCY
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

    RoomStay = Struct.new(:date, :price, :rate_plan, :available)

    def parse(response)
      availabilities = response.dig(:ga_hotel_avail_rs, :room_stays, :room_stay)
      return unless availabilities
      availabilities.map! do |room_stay|
        date      = Date.parse(room_stay[:time_span][:@start])
        price     = room_stay[:room_rates][:room_rate][:total][:@amount_after_tax].to_i
        rate_plan = room_stay[:rate_plans][:rate_plan][:@rate_plan_id]
        available = room_stay[:@availability_status] == 'OK'
        RoomStay.new(date, price, rate_plan, available)
      end
    end

    #todo: move to common helper for +Price+ and +Booker+
    def extract_total_from(response)
      rates = parse response
      return unless rates
      rate_plan = get_best_rate_plan rates
      rate_plan[1].map(&:price).inject(0) { |sum, price| sum + price } unless rate_plan.blank?
    end

    #todo: move to common helper for +Price+ and +Booker+
    def get_best_rate_plan(rates)
      available_rates = rates.group_by(&:rate_plan).select { |_, stays| stays.all?(&:available) }
      available_rates.min_by { |_, stays| stays.map(&:price).inject(0) { |sum, price| sum + price } } if available_rates.any?
    end

  end
end