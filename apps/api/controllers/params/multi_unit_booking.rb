require_relative "booking"

module API::Controllers::Params

  # +API::Controllers::Params::MultiUnitBooking
  #
  # Parameters declaration and validation for create booking. This is
  # shared among all partner multi unit booking calls, and ensures that required parameters
  # are present and in an acceptable format.
  #
  # If the parameters given are not valid, booking controllers that include this
  # module will return a 422 HTTP status, with a response payload that reports
  # the errors in the parameters.
  class MultiUnitBooking < Booking

    param :unit_id, presence: true, type: String

  end

end
