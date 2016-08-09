module Kigo::Calendar

  TimeInterval = Struct.new(:interval) do
    # returns days count computed by NIGHT, MONTH, YEAR unit
    # for some reasons period number might be zero
    def days
      return if interval['NUMBER'].zero?
      multiplier = { 'MONTH' => 30, 'YEAR' => 365 }.fetch(interval['UNIT'], 1)
      interval['NUMBER'] * multiplier
    end
  end

  class Period

    attr_reader :start_date, :end_date, :min_stay, :amounts

    def initialize(period)
      @start_date = Date.parse(period['CHECK_IN'])
      @end_date   = Date.parse(period['CHECK_OUT'])
      @min_stay   = period['STAY_MIN']
      @amounts    = period['NIGHTLY_AMOUNTS']
    end

    def entries
      start_date..end_date.map do |date|
        build_entry(date)
      end
    end

    def valid?
      valid_range.include?(start_date..end_date)
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
      amounts.min_by { |amount| amount['amount'].to_f }
    end

    def minimum_stay
      TimeInterval.new(min_stay).days
    end

    def valid_range
      year_from_today = Date.today + 365
      Date.today..year_from_today
    end
  end
end