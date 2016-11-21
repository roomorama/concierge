# This module provides convenient methods
# for constructing common booking errors
module Concierge::Errors::Booking

  ERROR_CODES_WITH_SUCCESS_RESPONSE = [:not_available]

  def not_available
    Result.error(:not_available, "Property not available for booking")
  end
end
