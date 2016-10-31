# This module provides convenient methods
# for constructing common quote errors
module Concierge::Errors::Quote
  def check_in_too_near
    Result.error(:check_in_too_near, "Selected check-in date is too near")
  end

  def check_in_too_far
    Result.error(:check_in_too_far, "Selected check-in date is too far")
  end

  def stay_too_short(min_stay)
    Result.error(:stay_too_short, "The minimum number of nights to book this apartment is #{min_stay}")
  end
end
