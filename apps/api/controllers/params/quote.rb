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
      messages = Hash.new { |h, k| h[k] = [] }

      errors.each do |error|
        attr = error.attribute

        case error.validation
        when :presence
          messages[attr] << "#{attr} is required"
        when :format
          messages[attr] << "#{attr}: invalid format"
        else
          messages[attr] << "#{attr} is invalid"
        end
      end

      messages
    end

    # Returns a +Date+ representation of the check-in date given in the call.
    # If the parameter cannot be parsed to a valid date, this method will just
    # return the check-in parameter intact.
    def check_in
      self[:check_in] && Date.parse(self[:check_in])
    rescue ArgumentError
      # check-in parameter is not a valid date
      self[:check_in]
    end

    # Returns a +Date+ representation of the check-out date given in the call.
    # If the parameter cannot be parsed to a valid date, this method will just
    # return the check-out parameter intact.
    def check_out
      self[:check_out] && Date.parse(self[:check_out])
    rescue ArgumentError
      # check-out parameter is not a valid date
      self[:check_out]
    end

    def stay_length
      if check_in && check_out
        check_out - check_in
      end
    end

  end

end
