module JTB
  class ResponseParser

    ERROR_CODES = { unit_not_found: 'FZZRC52' , invalid_request: 'GACZ005'}
    RoomStay = Struct.new(:date, :price, :rate_plan, :available)

    def parse_quote(response)
      if response[:ga_hotel_avail_rs][:errors]
        error = response[:ga_hotel_avail_rs][:errors][:error_info]
        return Result.error(ERROR_CODES.key(error[:@code]), error[:@short_text])
      end
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

    private

    def build_quotation(params)
      Quotation.new(
        property_id: params[:property_id],
        check_in:    params[:check_in].to_s,
        check_out:   params[:check_out].to_s,
        guests:      params[:guests],
      )
    end

  end
end