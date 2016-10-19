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
    def value
      min_stay = [prop_min_stay.to_i, cal_min_stay.to_i].max

      if min_stay.zero?
        invalid_min_stay_error
      else
        Result.new(min_stay)
      end
    end

    private
    def invalid_min_stay_error
      desc = "Min stay was not defined both for property and calendar entry"
      Result.error(:invalid_min_stay, desc)
    end
  end
end
