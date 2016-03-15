module JTB
  # JTB provide list of availabilities for each day with multiple rate plans
  # +RatePlan+ have to keep sum of daily prices and check if all days are available
  RatePlan = Struct.new(:rate_plan, :total, :available)

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
      'GACZ005' => :invalid_request
    }

    # parses the response of a +parse_rate_plan+ API call. Response is a +Hash+
    #
    # Returns a +Result+ instance wrapping a +RatePlan+ object
    # in case the response is successful. Possible errors that could
    # happen in this step are:
    #
    # +unit_not_found+:  the response sent back if unit not found
    # +invalid_request+: if property not found
    def parse_rate_plan(response)
      response = wrap(response)
      return unrecognised_response(response) unless response[:ga_hotel_avail_rs]

      if response.get('ga_hotel_avail_rs.errors')
        code = response.get('ga_hotel_avail_rs.errors.error_info.@code')
        if code
          return Result.error(error_code(code), response.to_h.to_s)
        else
          return unrecognised_response(response)
        end
      end

      rates = response.get('ga_hotel_avail_rs.room_stays.room_stay')
      if rates.blank?
        return Result.error(:unavailable_property, response)
      end

      rate_plans = group_to_rate_plans(rates)
      rate_plan  = get_best_rate_plan(rate_plans)
      if rate_plan
        Result.new(rate_plan)
      else
        Result.error(:unavailable_rate_plans, response)
      end
    end


    def parse_booking(response)
      response = wrap(response)
      if response.get('ga_hotel_avail_rs.errors')
        Result.error(:some, response)
      else
        Result.new(Reservation.new)
      end
    end

    private

    def error_code(code)
      ERROR_CODES.fetch(code, :request_error)
    end

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
          available: room_stay[:@availability_status] == 'OK'
        }
      end
      grouped_rates = rates.group_by { |rate| rate[:rate_plan] }
      grouped_rates.map do |rate_plan, rates|
        total     = rates.map { |rate| rate[:price] }.reduce(:+)
        available = rates.all? { |rate| rate[:available] }
        RatePlan.new(rate_plan, total, available)
      end
    end


    # get cheapest +RatePlan+
    # rate_plans = [
    #   <struct JTB::RatePlan rate_plan="good rate", total=4100, available=true>,
    #   <struct JTB::RatePlan rate_plan="abc", total=2100, available=false>,
    #   <struct JTB::RatePlan rate_plan="expensive_rate", total=8100, available=true>
    # ]
    #
    # get_best_rate_plan(rate_plans)
    # # => #<struct JTB::ResponseParser::RatePlan rate_plan="good rate", total=4100, available=true>
    def get_best_rate_plan(rate_plans)
      rate_plans.select(&:available).min_by(&:total)
    end

    def unrecognised_response(response)
      Result.error(:unrecognised_response, response)
    end

    #  wraps +Hash+ object to +Hanami::Action::Params+ to make flexible usage with indifferent access
    # and avoiding NoMethodError for deep nested objects
    #
    # Example:
    #
    #   wise_hash = Hanami::Action::Params.new({ name: 'Alex', foo: { bar: { '@strange_key' => 20 } } })
    #   wise_hash[:name]  # => "Alex"
    #   wise_hash['name'] # => "Alex"
    #   wise_hash.get('foo.bar.@strange_key') # => 20
    #   wise_hash.get('foo.bar.unknown') # => nil
    def wrap(response)
      Hanami::Action::Params.new(response)
    end

  end
end