module JTB
  # JTB provide list of availabilities for each day with multiple rate plans
  # +RatePlan+ have to keep sum of daily prices and check if all days are available
  # there is +occupancy+ attribute to define maximum guests for each rate plan - effects to price
  RatePlan = Struct.new(:rate_plan, :total, :available, :occupancy)

  # +JTB::ResponseParser+
  #
  # This class is responsible for managing the response sent by JTB's API
  # for different API calls.
  #
  # Usage
  #
  #   parser = JTB::ResponseParser.new
  #   parser.parse_rate_plan(response_body)
  #   # => #<Result error=nil value=RatePlan>
  #
  # See documentation of this class instance methods for their description
  # and possible errors.
  class ResponseParser
    # error codes and meanings took from documentation. Check wiki
    ERROR_CODES = {
      'FZZRC52' => :unit_not_found,
      'GACZ005' => :invalid_request,
      'FZZRC14' => :invalid_number_of_guests
    }

    # parses the response of a +parse_rate_plan+ API call. Response is a +Hash+
    #
    # Returns a +Result+ instance wrapping a +RatePlan+ object
    # in case the response is successful. Possible errors that could
    # happen in this step are:
    #
    # +unit_not_found+:  the response sent back if unit not found
    # +invalid_request+: if property not found
    def parse_rate_plan(response, params)
      response = Concierge::SafeAccessHash.new(response)

      return unrecognised_response(response) unless response[:ga_hotel_avail_rs]

      errors = response[:ga_hotel_avail_rs][:errors]
      return handle_error(errors) if errors

      rates = response.get('ga_hotel_avail_rs.room_stays.room_stay')
      return Result.error(:unavailable_property, response) unless rates

      rate_plans = group_to_rate_plans(rates)
      rate_plan  = get_best_rate_plan(rate_plans, guests: params[:guests])
      if rate_plan
        Result.new(rate_plan)
      else
        Result.error(:unavailable_rate_plans, response)
      end
    end


    def parse_booking(response)
      response = Concierge::SafeAccessHash.new(response)
      return unrecognised_response(response) unless response[:ga_hotel_res_rs]

      errors = response[:ga_hotel_res_rs][:errors]
      return handle_error(errors) if errors

      booking = response.get('ga_hotel_res_rs.hotel_reservations.hotel_reservation')
      return unrecognised_response(response) unless booking
      if booking[:@res_status] == 'OK'
        Result.new(booking[:unique_id][:@id])
      else
        Result.error(:fail_booking, response)
      end
    end

    private

    # JTB provides so deep nested scattered response. This method prepares rates and returns +RatePlan+ list
    #
    # input:
    #  [
    #     {:rate_plans=>{:rate_plan => {...}},
    #     {:rate_plans=>{:rate_plan => {...}},
    #     ...
    # ]

    # output:
    #  [
    #    <struct JTB::ResponseParser::RatePlan rate_plan="good rate", total=4100, available=true>,
    #    <struct JTB::ResponseParser::RatePlan rate_plan="abc", total=2100, available=false>,
    #    ...
    # ]
    def group_to_rate_plans(rates)
      rates.map! do |room_stay|
        {
          date:      Date.parse(room_stay[:time_span][:@start]),
          price:     room_stay[:room_rates][:room_rate][:total][:@amount_after_tax].to_i,
          rate_plan: room_stay[:rate_plans][:rate_plan][:@rate_plan_id],
          available: room_stay[:@availability_status] == 'OK',
          occupancy: room_stay[:room_types][:room_type][:occupancy][:@max_occupancy].to_i
        }
      end
      grouped_rates = rates.group_by { |rate| rate[:rate_plan] }
      grouped_rates.map do |rate_plan, rates|
        total     = rates.map { |rate| rate[:price] }.reduce(:+)
        available = rates.all? { |rate| rate[:available] }
        occupancy = rates.first[:occupancy]
        RatePlan.new(rate_plan, total, available, occupancy)
      end
    end

    # get cheapest +RatePlan+
    # rate_plans = [
    #   <struct JTB::RatePlan total=4100, occupancy=2 available=true rate_plan="good rate">,
    #   <struct JTB::RatePlan total=2100, occupancy=1 available=true, rate_plan="small occupancy"">,
    #   <struct JTB::RatePlan total=2100, occupancy=2 available=false, rate_plan="abc"">,
    #   <struct JTB::RatePlan total=8100, occupancy=2 available=true, rate_plan="expensive_rate">
    # ]
    #
    # get_best_rate_plan(rate_plans, guests: 2)
    # # => #<struct JTB::ResponseParser::RatePlan total=4100, occupancy=2, available=true, rate_plan="good rate">
    def get_best_rate_plan(rate_plans, guests:)
      available_rate_plans = rate_plans.select { |rate_plan| rate_plan.available && rate_plan.occupancy >= guests }
      available_rate_plans.min_by(&:total)
    end

    def error_code(code)
      ERROR_CODES.fetch(code, :request_error)
    end

    def unrecognised_response(response)
      Result.error(:unrecognised_response, response)
    end

    def handle_error(response)
      code = response.get("error_info.@code")
      if code
        Result.error(error_code(code), response)
      else
        unrecognised_response(response)
      end
    end

  end
end