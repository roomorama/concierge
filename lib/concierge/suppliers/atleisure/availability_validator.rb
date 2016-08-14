module AtLeisure
  # +AtLeisure::AvailabilityValidator+
  #
  # Business validation of AtLeisure stay.
  # Each stay should be actual by date and not to be 'on request'.
  class AvailabilityValidator

    attr_reader :availability, :today

    def initialize(availability, today)
      @availability = availability
      @today = today
    end

    def valid?
      check_in > today && !on_request?
    end

    private

    def on_request?
      availability['OnRequest'] == 'Yes'
    end

    def check_in
      Date.parse(availability['ArrivalDate'])
    end
  end
end