# This module provides convenient methods
# for constructing common quote errors
module Concierge::Errors::Quote

  ERROR_CODES_WITH_SUCCESS_RESPONSE = [:check_in_too_near, :check_in_too_far, :stay_too_short]

  def check_in_too_near
    Result.error(:check_in_too_near, "Selected check-in date is too near")
  end

  def check_in_too_far
    Result.error(:check_in_too_far, "Selected check-in date is too far")
  end

  def stay_too_short(min_stay)
    Result.error(:stay_too_short, "The minimum number of nights to book this apartment is #{min_stay}")
  end

  def not_instant_bookable
    Result.error(:property_not_instant_bookable, 'Instant booking is not supported for the given period')
  end

  def max_guests_exceeded(max = nil)
    message =
      if max
        "The maximum number of guests to book this apartment is #{max}"
      else
        "The maximum number of guests to book this apartment is exceeded"
      end

    mismatch(message, caller)
    Result.error(:max_guests_exceeded, message)
  end

  private
  def mismatch(message, backtrace)
    response_mismatch = Concierge::Context::ResponseMismatch.new(
      message: message,
      backtrace: backtrace
    )

    Concierge.context.augment(response_mismatch)
  end
end
