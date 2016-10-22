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
    def parse_rate_plan(response, guests, rate_plans_ids)
      response = Concierge::SafeAccessHash.new(response)

      unless response[:ga_hotel_avail_rs]
        return no_field_error('ga_hotel_avail_rs')
      end

      errors = response[:ga_hotel_avail_rs][:errors]
      return handle_error(errors) if errors

      rates = extract_rates(response)
      return unavailable_rate_plan if rates.empty?

      rate_plans = group_to_rate_plans(rates, rate_plans_ids)
      rate_plan  = get_best_rate_plan(rate_plans, guests: guests)

      return unavailable_rate_plan unless rate_plan

      Result.new(rate_plan)
    end


    def parse_booking(response)
      response = Concierge::SafeAccessHash.new(response)
      unless response[:ga_hotel_res_rs]
        return no_field_error('ga_hotel_res_rs')
      end

      errors = response[:ga_hotel_res_rs][:errors]
      return handle_error(errors) if errors

      booking = response.get('ga_hotel_res_rs.hotel_reservations.hotel_reservation')
      unless booking
        return no_field_error('ga_hotel_res_rs.hotel_reservations.hotel_reservation')
      end

      if booking[:@res_status] == 'OK'
        Result.new(booking[:unique_id][:@id])
      else
        non_successful_booking_error
      end
    end

    private

    def unavailable_rate_plan
      Result.new(RatePlan.new(nil, nil, false))
    end

    # JTB provides so deep nested scattered response. This method prepares rates, selects
    # rate plans only from rate_plans_ids and returns +RatePlan+ list
    #
    # input:
    #  [
    #     {:rate_plans=>{:rate_plan => {...}},
    #     {:rate_plans=>{:rate_plan => {...}},
    #     ...
    #  ],
    #  ["good rate", "abc"]

    # output:
    #  [
    #    <struct JTB::ResponseParser::RatePlan rate_plan="good rate", total=4100, available=true>,
    #    <struct JTB::ResponseParser::RatePlan rate_plan="abc", total=2100, available=false>,
    #    ...
    # ]
    def group_to_rate_plans(rates, rate_plans_ids)
      prepared_rates = []
      rates.each do |room_stay|
        room_stay = Concierge::SafeAccessHash.new(room_stay)

        rate_plan_id = room_stay[:rate_plans][:rate_plan][:@rate_plan_id]
        if rate_plans_ids.include?(rate_plan_id)
          prepared_rates << {
            date:      Date.parse(room_stay[:time_span][:@start]),
            price:     room_stay[:room_rates][:room_rate][:total][:@amount_after_tax].to_i,
            rate_plan: rate_plan_id,
            available: room_stay[:@availability_status] == 'OK',
            occupancy: room_stay[:room_types][:room_type][:occupancy][:@max_occupancy].to_i
          }
        end
      end
      grouped_rates = prepared_rates.group_by { |rate| rate[:rate_plan] }
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

    # extracts the collection of rates from a JTB response. As case rate plans might be a
    # collection(Array) or a single item (Hash), the response will be converted to collection. Otherwise,
    # returns the collection of rate plans (which can be empty in case the unit is not
    # available on the selected dates.).
    def extract_rates(response)
      rates = response.get('ga_hotel_avail_rs.room_stays.room_stay')
      Array(rates)
    end

    def error_code(code)
      ERROR_CODES.fetch(code, :request_error)
    end

    def no_field_error(field_name)
      message = "Expected field `#{field_name}` to be defined, but it was not."
      mismatch(message, caller)
      Result.error(:unrecognised_response, message)
    end

    def non_successful_booking_error
      message = "JTB indicated the booking not to have been performed successfully." +
        " The `@res_status` field was supposed to be equal to `OK`, but it was not."

      mismatch(message, caller)
      Result.error(:fail_booking, message)
    end

    def unsuccessful_response_error(code)
      label   = "Non-successful Response"
      message = "The response indicated errors while processing the request. Check " +
        "the `errors` field."

      report_message(label, message, caller)
      Result.error(code, message)
    end

    def no_field(field_name)
      message = "Expected field `#{field_name}` to be defined, but it was not."
      mismatch(message, caller)
    end

    def mismatch(message, backtrace)
      response_mismatch = Concierge::Context::ResponseMismatch.new(
        message:   message,
        backtrace: backtrace
      )

      Concierge.context.augment(response_mismatch)
    end

    def report_message(label, message, backtrace)
      message = Concierge::Context::Message.new(
        label:     label,
        message:   message,
        backtrace: backtrace
      )

      Concierge.context.augment(message)
    end

    def handle_error(response)
      code = response.get("error_info.@code")
      if code
        unsuccessful_response_error(error_code(code))
      else
        no_field_error("error_info.@code")
      end
    end

  end
end
