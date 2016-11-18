module THH
  # +THH::Calendar+
  #
  # Util class for work with THH rates and calendar.
  # Allows to calculate min_stay, min_rate and get day by day
  # rates and book info
  class Calendar
    attr_reader :rates, :booked_days, :length

    # Arguments:
    # * raw_rates - +Array+ of +Concierge::SafeAccessHash+ getting from raw
    #               THH property response (parsed by Nori) by key 'response.rates.rate'
    # * raw_booked_dates - +Array+ of +String+ getting from
    #                       raw THH property response (parsed by Nori)
    #                       by key 'response.calendar.booked.date'
    # * length - count of days from today calendar works with
    def initialize(raw_rates, raw_booked_dates, length)
      @length = length

      from = calendar_start
      to = calendar_end

      # Set of booked dates
      @booked_days = actual_booked_days(raw_booked_dates, from, to)
      @rates = actual_rates(raw_rates, from, to)
    end

    def min_stay
      available_days.values.map { |r| r[:min_nights] }.min
    end

    def min_rate
      available_days.values.map { |r| r[:night] }.min
    end

    # Returns Hash where keys are days and values are Hash with rate and min stay info
    def rates_days
      @rates_days ||= {}.tap do |days|
        rates.each do |r|
          from = [calendar_start, r[:start_date]].max
          to = [calendar_end, r[:end_date]].min
          if from <= to
            (from..to).each do |day|
              # One date can have several rates with different min_nights,
              # To fill calendar Concierge uses max minimum stay and max price.
              # It's hard to use min minimum stay because of THH's rule: if booking is less than min stay - it must be
              # close to already existing booking (another words they allow to book less then max(min_nights)
              # only for small gaps inside existing booking calendar or if user's small vacation is near some other reservation)
              cur_r = days[day]
              if cur_r
                days[day] = {
                  min_nights: [cur_r[:min_nights], r[:min_nights]].max,
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

    def has_available_days?
      ! (Set.new(rates_days.keys) - booked_days).empty?
    end

    private

    def actual_rates(raw_rates, from, to)
      raw_rates.map do |r|
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

    def actual_booked_days(raw_booked_dates, from, to)
      Set.new(
        raw_booked_dates
          .map { |d| Date.parse(d) }
          .select { |d| from <= d && d <= to }
      )
    end

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