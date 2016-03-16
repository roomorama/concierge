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
      ErrorMessages.new(errors).generate
    end

    # Returns a +Date+ representation of the check-in date given in the call.
    # If the parameter cannot be parsed to a valid date, this method will
    # return +nil+.
    def check_in_date
      self[:check_in] && Date.parse(self[:check_in])
    rescue ArgumentError
      # check-in parameter is not a valid date
    end

    # Returns a +Date+ representation of the check-out date given in the call.
    # If the parameter cannot be parsed to a valid date, this method will
    # return +nil+.
    def check_out_date
      self[:check_out] && Date.parse(self[:check_out])
    rescue ArgumentError
      # check-out parameter is not a valid date
    end

    def stay_length
      if check_in_date && check_out_date
        check_out_date - check_in_date
      end
    end

  end

end
