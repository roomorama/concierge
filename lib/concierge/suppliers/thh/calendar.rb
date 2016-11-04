module THH
  # +THH::Calendar+
  #
  # Util class for work with THH rates and calendar.
  # Allows to calculate min_stay, min_rate and get day by day
  # rates and book info
  class Calendar
    attr_reader :rates, :booked_periods, :length

    # length - count of days from today calendar works with
    def initialize(rates, booked_periods, length)
      @length = length

      from = calendar_start
      to = calendar_end

      # Filter only actual periods.
      # NOTE: End date of period is not booked
      @booked_periods = booked_periods.map do |p|
        {
          date_from: Date.parse(p['@date_from']),
          date_to: Date.parse(p['@date_to']) - 1
        }
      end.select do |p|
        p[:date_from] <= to && from <= p[:date_to]
      end

      @rates = rates.map do |r|
        {
          start_date: Date.parse(r['start_date']),
          end_date: Date.parse(r['end_date']),
          night: rate_to_f(r['night']),
          min_nights: r['min_nights'].to_i
        }
      end.select do |r|
        r[:start_date] <= to && from <= r[:end_date]
      end
    end

    def min_stay
      available_days.values.map { |r| r[:min_nights] }.min
    end

    def min_rate
      available_days.values.map { |r| r[:night] }.min
    end

    def rates_days
      @rates_days ||= {}.tap do |days|
        rates.each do |r|
          from = [calendar_start, r[:start_date]].max
          to = [calendar_end, r[:end_date]].min
          if from <= to
            (from..to).each do |day|
              # One date can have several rates with different min_nights,
              # To fill calendar Concierge uses min minimum stay and max price.
              cur_r = days[day]
              if cur_r
                days[day] = {
                  min_nights: [cur_r[:min_nights], r[:min_nights]].min,
                  night:      [cur_r[:night], r[:night]].max
                }
              else
                days[day] = {
                  min_nights: r[:min_nights],
                  night:      r[:night]
                }
              end
            end
          end
        end
      end
    end

    def booked_days
      @booked_days ||= Set.new.tap do |days|
        booked_periods.each do |p|
          from = [calendar_start, p[:date_from]].max
          to = [calendar_end, p[:date_to]].min
          if from <= to
            days.merge(from..to)
          end
        end
      end
    end

    private

    def calendar_start
      Date.today
    end

    def calendar_end
      calendar_start + length
    end

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

    def rate_to_f(rate)
      rate.gsub(/[,\s]/, '').to_f
    end
  end
end