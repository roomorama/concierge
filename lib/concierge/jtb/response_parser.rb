module JTB
  # +JTB::ResponseParser+
  #
  # This class is responsible for managing the response sent by JTB's API
  # for different API calls.
  #
  # Usage
  #
  #   parser = JTB::ResponseParser.new
  #   parser.parse_quote(response_body, request_params)
  #   # => #<Result error=nil value=Quotation>
  #
  # See documentation of this class instace methods for their description
  # and possible errors.
  class ResponseParser
    # error codes and meanings taked from documentation. Check wiki
    ERROR_CODES = { unit_not_found: 'FZZRC52', invalid_request: 'GACZ005' }

    # parses the response of a +quote_price+ API call.
    #
    # Returns a +Result+ instance wrapping a +Quotation+ object
    # in case the response is successful. Possible errors that could
    # happen in this step are:
    #
    # +unit_not_found+:  the response sent back if unit not found
    # +invalid_request+: if property not found
    def parse_quote(response, params)
      if response[:ga_hotel_avail_rs][:errors]
        error = response[:ga_hotel_avail_rs][:errors][:error_info]
        return Result.error(error_code(error[:@code]), error[:@short_text])
      end

      rates = response.dig(:ga_hotel_avail_rs, :room_stays, :room_stay)
      if rates.empty?
        return Result.error(:unavailable_property, 'There is no room stays')
      end

      rate_plans = group_to_rate_plans(rates)
      rate_plan  = get_best_rate_plan(rate_plans)

      if rate_plan
        quotation = Quotation.new(params)
        quotation.total = rate_plan.total
        quotation.currency = Price::CURRENCY
        quotation.available = true
        Result.new(quotation)
      else
        Result.error(:unavailable_property, 'There is no available rate plans')
      end
    end

    private

    def error_code(code)
      ERROR_CODES.key(code)
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

    # JTB provide list of availabilities for each day with multiple rate plans
    # +RatePlan+ have to keep sum of daily prices and check if all days are available
    RatePlan = Struct.new(:rate_plan, :total, :available)

    # get cheapest +RatePlan+
    # rate_plans = [
    #   <struct JTB::ResponseParser::RatePlan rate_plan="good rate", total=4100, available=true>,
    #   <struct JTB::ResponseParser::RatePlan rate_plan="abc", total=2100, available=false>,
    #   <struct JTB::ResponseParser::RatePlan rate_plan="expensive_rate", total=8100, available=true>
    # ]
    #
    # get_best_rate_plan(rate_plans)
    # # => #<struct JTB::ResponseParser::RatePlan rate_plan="good rate", total=4100, available=true>
    def get_best_rate_plan(rate_plans)
      rate_plans.select(&:available).min_by(&:total)
    end

  end
end