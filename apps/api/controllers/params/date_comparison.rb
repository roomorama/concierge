# API::Controllers::Params::DateComparison
#
# This class is responsible for managing comparing dates where one of the
# dates should be before the other. This kind of rule applies to check-in/check-out
# dates when quoting stays or performing bookings, as well as when specifying
# date intervals to pull the availabilities calendar for a property.
#
# It checks whether one date is before the other, and creates an error in case
# that rule is not folllowed.
#
# Usage
#
#   dates = API::Controllers::Params::DateComparison.new(check_in: check_in, check_out: check_out)
#   if dates.valid?
#     process_request
#   else
#     dates.errors # => [#<Hanami::Validations::Error attribute="check_out"... >]
#   end
class API::Controllers::Params::DateComparison

  # +API::Controllers::Params::DateComparison::InvalidDatesError+
  #
  # This error class is raised if the dates given on initialization of the
  # +API::Controllers::Params::DateComparison+ class do not correspond to
  # the expectations.
  class InvalidDatesError < StandardError
    def initialize(dates)
      super("Expected a Hash with two date elements, got: #{dates} (#{dates.class})")
    end
  end

  attr_reader :dates, :errors

  # +dates+ - a +Hash+ containing two keys:
  #   * the first element is the date that should be _before_
  #   * the second element is the date that should be _after_
  #
  # The keys in the Hash are used to produce error messages with meaningful names.
  #
  # Example
  #
  #   API::Controllers::Params::DateComparison.new(check_in: params[:check_in], check_out: params[:check_out])
  #   API::Controllers::Params::DateComparison.new(start_date: params[:start_date], end_date: params[:end_date])
  #
  # This method raises an error if the hash does not contain exactly two keys as
  # illustrated above.
  def initialize(dates)
    @dates  = dates
    @errors = []

    validate_dates!
  end

  def valid?
    errors.clear
    validate_dates_order

    errors.empty?
  end

  def duration
    if before_date && after_date
      after_date - before_date
    end
  end


  private

  def validate_dates_order
    if duration && duration <= 0
      before = dates.to_a.first # format: [:check_in, "2016-05-22"]
      after  = dates.to_a.last  # format: [:check_out, "2016-05-12"]

      error_name = "#{after.first}_before_#{before.first}".downcase.to_sym
      errors << Hanami::Validations::Error.new(after.first, error_name, true, after.last)
    end
  end

  # Returns a +Date+ representation of the first date given on initialization.
  # If the parameter cannot be parsed to a valid date, this method will
  # return +nil+.
  def before_date
    before = dates[dates.keys.first]
    before && Date.parse(before)
  rescue ArgumentError
    # check-in parameter is not a valid date
  end

  # Returns a +Date+ representation of the last date given on initialization.
  # If the parameter cannot be parsed to a valid date, this method will
  # return +nil+.
  def after_date
    after = dates[dates.keys.last]
    after && Date.parse(after)
  rescue ArgumentError
    # check-out parameter is not a valid date
  end

  # ensures that the +dates+ parameter is valid, containing two elements
  def validate_dates!
    if dates.keys.size != 2
      raise InvalidDatesError.new(dates)
    end
  end

end
