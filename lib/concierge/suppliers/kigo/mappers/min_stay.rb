module Kigo::Mappers
  # It's possible that min_stay value for property and min_stay value for
  # calendar entry can be different.
  #
  # This class solves the problem of determining which min_stay value
  # we should use.
  #
  # This class should be used everywhere where we need to set min_stay values.
  class MinStay
    attr_reader :prop_min_stay, :cal_min_stay

    def initialize(prop_min_stay, cal_min_stay)
      @prop_min_stay = prop_min_stay
      @cal_min_stay  = cal_min_stay
    end

    # Compare and return the most strict min_stay value.
    # Return nil if both prop_min_stay and cal_min_stay are zero
    def value
      min_stay = [prop_min_stay.to_i, cal_min_stay.to_i].max

      min_stay.zero? ? nil : min_stay
    end
  end
end
