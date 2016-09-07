class Kigo::Calendar
  # +Kigo::Calendar::Period+
  #
  # performs availabilities list by specific periods
  class Period

    attr_reader :start_date, :end_date, :min_stay, :amounts

    def initialize(period)
      start_date = Date.parse(period['CHECK_IN'])
      end_date   = Date.parse(period['CHECK_OUT'])

      @start_date = define_start_date(start_date)
      @end_date   = define_end_date(end_date)
      @min_stay   = period['STAY_MIN']
      @amounts    = period['NIGHTLY_AMOUNTS']
    end

    def entries
      (start_date...end_date).map do |date|
        build_entry(date)
      end
    end

    def valid?
      valid_range.include?(start_date) && valid_range.include?(end_date)
    end

    private

    def build_entry(date)
      attrs = {
        date:             date,
        available:        true,
        nightly_rate:     nightly_rate,
        minimum_stay:     minimum_stay,
        checkin_allowed:  true,
        checkout_allowed: true
      }
      Roomorama::Calendar::Entry.new(attrs)
    end

    def nightly_rate
      amounts.map { |amount| amount['AMOUNT'].to_f }.min
    end

    def minimum_stay
      Kigo::TimeInterval.new(min_stay).days
    end

    def valid_range
      today..year_from_today
    end

    def define_start_date(date)
      date < today ? today : date
    end

    def define_end_date(date)
      date > year_from_today ? year_from_today : date
    end

    def today
      Date.today
    end

    def year_from_today
      today + 365
    end
  end
end