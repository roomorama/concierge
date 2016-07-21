module API::Controllers::Params

  # +API::Controllers::Params::Cancel
  #
  # Parameters declaration and validation for cancelling booking. This is
  # shared among all partner cancelation calls, and ensures that required parameters
  # are present and in an acceptable format.
  #
  # If the parameters given are not valid, quoting controllers that include this
  # module will return a 422 HTTP status, with a response payload that reports
  # the errors in the parameters.
  #
  class Cancel < API::Action::Params

    param :reference_number, presence: true, type: String

    # Constructs a map of errors for the request.
    #
    # Example
    #
    #   action.error_messages
    #   # => { reference_number: ["reference_number is required"] }
    #
    # The keys for the returned hash are attribute names (see the +param+ declaration list above)
    # and the values for each key is a list of errors for the attribute.
    def error_messages
      ErrorMessages.new(validation_errors).generate
    end

    # gathers errors from the parameter declaration
    def validation_errors
      errors.each.to_a
    end

  end

end
