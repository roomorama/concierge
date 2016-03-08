module API::Controllers::Params

  # +API::Controllers::Params::MultiUnitQuote
  #
  # Parameters declaration and validation for quoting booking stays. This is
  # shared among all multi unit partner quoting calls, and ensures that required parameters
  # are present and in an acceptable format.
  #
  # If the parameters given are not valid, quoting controllers that include this
  # module will return a 422 HTTP status, with a response payload that reports
  # the errors in the parameters.
  class MultiUnitQuote < Quote

    param :unit_id, presence: true, type: String

  end

end
