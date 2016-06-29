module API::Controllers::Params

  # +API::Controllers::Params::Calendar
  #
  # Parameters declaration and validation for getting the availabilities calendar
  # for a given property. This is shared among all partner calendar calls, and
  # ensures that required parameters are present and in an acceptable format.
  #
  # If the parameters given are not valid, quoting controllers that include this
  # module will return a 422 HTTP status, with a response payload that reports
  # the errors in the parameters.
  class Calendar < API::Action::Params

    DATE_FORMAT = /\d\d\d-\d\d-\d\d/

    param :property_id, presence: true, type: String
    param :from_date,   presence: true, type: String, format: DATE_FORMAT
    param :to_date,     presence: true, type: String, format: DATE_FORMAT

    # Constructs a map of errors for the request.
    #
    # Example
    #
    #   action.error_messages
    #   # => { property_id: ["property_id is required"] }
    def error_messages
      ErrorMessages.new(validation_errors).generate
    end

    # gathers errors from the parameter declaration as well as custom validations
    # defined on the +API::Controllers::Params::DateComparison+ class.
    def validation_errors
      date_comparison.valid?
      errors.each.to_a + date_comparison.errors
    end

    # include checking for travel date errors when validating parameters
    def valid?
      builtin_validations = super
      dates_validations   = date_comparison.valid?

      builtin_validations && dates_validation
    end

    private

    def date_comparison
      @date_comparison ||= DateComparison.new(from_date: self[:from_date], to_date: self[:to_date])
    end

  end

end
