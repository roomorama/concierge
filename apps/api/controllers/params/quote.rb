module API::Controllers::Params

  # +API::Controllers::Params::Quote
  #
  # Parameters declaration and validation for quoting booking stays. This is
  # shared among all partner quoting calls, and ensures that required parameters
  # are present and in an acceptable format.
  #
  # If the parameters given are not valid, quoting controllers that include this
  # module will return a 422 HTTP status, with a response payload that reports
  # the errors in the parameters.
  class Quote < API::Action::Params

    DATE_FORMAT = /\d\d\d-\d\d-\d\d/

    param :property_id, presence: true, type: String
    param :check_in,    presence: true, type: String, format: DATE_FORMAT
    param :check_out,   presence: true, type: String, format: DATE_FORMAT
    param :guests,      presence: true, type: Integer

    # Constructs a map of errors for the request.
    #
    # Example
    #
    #   action.error_messages
    #   # => { property_id: ["property_id is required"], check_in: ["check_in: invalid format"] }
    #
    # The keys for the returned hash are attribute names (see the +param+ declaration list above)
    # and the values for each key is a list of errors for the attribute.
    def error_messages
      ErrorMessages.new(validation_errors).generate
    end

    # gathers errors from the parameter declaration as well as custom validations
    # defined on the +API::Controllers::Params::TravelDates+ class.
    def validation_errors
      travel_dates.valid?
      errors.each.to_a + travel_dates.errors
    end

    def stay_length
      travel_dates.stay_length
    end

    # include checking for travel date errors when validating parameters
    def valid?
      builtin_validations      = super
      travel_dates_validations = travel_dates.valid?

      builtin_validations && travel_dates_validations
    end

    private

    def travel_dates
      @travel_dates ||= TravelDates.new(self[:check_in], self[:check_out])
    end

  end

end
