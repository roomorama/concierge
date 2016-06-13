# API::Controllers::Params::TravelDates
#
# This class is responsible for managing check-in and check-out dates,
# and performing specific validations to them.
#
# It checks if the check-out date is past the check-in date, and creates
# an error in case it is not.
#
# Usage
#
#   travel_dates = API::Controllers::Params::TravelDates.new(check_in, check_out)
#   if travel_dates.valid?
#     process_request
#   else
#     travel_dates.errors # => [#<Hanami::Validations::Error attribute="check_out"... >]
#   end
class API::Controllers::Params::TravelDates
  attr_reader :check_in, :check_out, :errors

  # +check_in+ and +check_out+ - Strings with travel dates, as originally provided
  #                              in the request.
  def initialize(check_in, check_out)
    @check_in  = check_in
    @check_out = check_out
    @errors    = []
  end

  def valid?
    errors.clear
    validate_stay_length

    errors.empty?
  end

  def stay_length
    if check_in_date && check_out_date
      check_out_date - check_in_date
    end
  end


  private

  def validate_stay_length
    if stay_length && stay_length <= 0
      errors << Hanami::Validations::Error.new(:check_out, :check_out_before_check_in, true, check_out)
    end
  end

  # Returns a +Date+ representation of the check-in date given in the call.
  # If the parameter cannot be parsed to a valid date, this method will
  # return +nil+.
  def check_in_date
    check_in && Date.parse(check_in)
  rescue ArgumentError
    # check-in parameter is not a valid date
  end

  # Returns a +Date+ representation of the check-out date given in the call.
  # If the parameter cannot be parsed to a valid date, this method will
  # return +nil+.
  def check_out_date
    check_out && Date.parse(check_out)
  rescue ArgumentError
    # check-out parameter is not a valid date
  end

end
