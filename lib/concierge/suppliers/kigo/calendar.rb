module Kigo
  # +Kigo::TimeInterval+
  #
  # represents days count according to +UNIT+ type
  # possible unit types NIGHT, MONTH, YEAR
  TimeInterval = Struct.new(:interval) do
    def days
      return 1 if interval['NUMBER'].zero?
      multiplier = { 'MONTH' => 30, 'YEAR' => 365 }.fetch(interval['UNIT'], 1)
      interval['NUMBER'].to_i * multiplier
    end
  end

  #  +Kigo::Calendar+
  #
  # responsible for performing date periods and availabilities list
  # to +Roomorama::Calendar+ instance
  class Calendar

    attr_reader :property, :entries

    def initialize(property)
      @property = property
      @entries  = []
    end

    def perform(pricing, availabilities)
      process_periods(pricing)
      set_availabilities(availabilities)

      entries.each do |entry|
        calendar.add(entry)
      end

      Result.new(calendar)
    end

    private

    def calendar
      @calendar ||= Roomorama::Calendar.new(property.identifier)
    end

    def process_periods(pricing)
      periods = safe_access(pricing).get('PRICING.RENT.PERIODS')
      Array(periods).each do |period|
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

    # marks existent +entries+ as available or not otherwise create default entry
    # availability influenced by two params:
    #   * MAX_LOS - maximum stay length. Zero means unavailable
    #   * AVAILABLE_UNITS - supplier's property might be multi unit
    def set_availabilities(availabilities)
      availabilities['AVAILABILITY'].each do |availability|
        date      = availability['DATE']
        available = availability['MAX_LOS'] > 0 && availability['AVAILABLE_UNITS'] > 0
        entry     = find_entry(date)

        unless entry
          entry              = build_entry(date)
          entry.nightly_rate = default_nightly_rate
          entries << entry
        end

        entry.available = available
      end
    end

    def find_entry(date)
      return if entries.empty?
      entries.find { |entry| entry.date.to_s == date }
    end

    def build_entry(date)
      Roomorama::Calendar::Entry.new(date: date)
    end

    def default_nightly_rate
      property.data[:nightly_rate]
    end

    def safe_access(hash)
      Concierge::SafeAccessHash.new(hash)
    end
  end
end