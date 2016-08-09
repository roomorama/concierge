module Kigo

  class Calendar

    attr_reader :property_identifier, :entries

    def initialize(identifier)
      @property_identifier = identifier
      @entries = []
    end

    def perform(pricing, availabilities)
      process_periods(pricing)
      # updated_entries = set_availabilities(availabilities)
      entries.each do |entry|
        calendar.add(entry)
      end

      Result.new(calendar)
    end

    private

    def calendar
      @calendar ||= Roomorama::Calendar.new(property_identifier)
    end

    def process_periods(pricing)
      periods = wrapped(pricing).get('PRICING.RENT.PERIODS')
      return if periods.empty?
      periods.each do |period|
        period = wrap_period(period)
        entries.concat(period.entries) if period.valid?
      end
    end

    def wrap_period(period)
      if period['WEEKLY']
        Kigo::Calendar::WeeklyPeriod.new(period)
      else
        Kigo::Calendar::Period.new(period)
      end
    end

    def set_availabilities(availabilities)

    end

    def wrapped(hash)
      Concierge::SafeAccessHash.new(hash)
    end
  end
end