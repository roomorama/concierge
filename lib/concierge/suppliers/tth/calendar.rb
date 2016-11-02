module THH
  # +THH::Calendar+
  #
  # Util class for work with THH rates and calendar.
  #
  # Usage:
  #
  #
  class Calendar
    attr_reader :rates, :booked_periods

    # length - count of days from today calendar works with
    def initialize(rates, booked_periods, length)
      today = Date.today
      to = today + length

      # Filter only actual periods.
      # NOTE: End date of period is not booked
      @booked_periods = booked_periods.map do |p|
        new_p = p.dup
        new_p['date_from'] = Date.parse(r['date_from'])
        new_p['date_to'] = Date.parse(r['date_to']) - 1
      end.select do |p|
        p['date_from'] <= to && today <= p['date_to']
      end

      @rates = rates.map do |r|
        new_r = r.dup
        new_r['start_date'] = Date.parse(r['start_date'])
        new_r['end_date'] = Date.parse(r['end_date'])
      end.select do |r|
        r['start_date'] <= to && today < r['end_date']
      end
    end

    def min_stay
      available_days.values.map { |r| r['min_nights'].to_i }.min
    end

    def min_rate
      available_days.values.map { |r| r['night'].to_f }.min
    end

    def rates_days
      @rates_days ||= {}.tap do |days|
        rates.each do |r|
          (r['start_date']..r['end_date']).each { |day| days[day] = r }
        end
      end
    end

    def booked_days
      @booked_days ||= Set.new.tap do |days|
        booked_periods.each do |p|
          days | (p['date_from']..p['date_to'])
        end
      end
    end

    private

    def available_days
      @available_days ||= begin
        keys = Set.new(rates_days.keys) - booked_days
        slice(rates_days, keys)
      end
    end

    def slice(hash, keys)
      {}.tap do |h|
        keys.each do |k|
          h[k] = hash[k]
        end
      end
    end
  end
end