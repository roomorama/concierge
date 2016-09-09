module Avantio
  module Mappers
    # +Avantio::Mappers::RoomoramaCalendar+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object
    # from data getting from Avantio.
    class RoomoramaCalendar
      attr_reader :property_id, :rate, :availability, :rule, :length

      # Arguments
      #
      #   * +propertyid+ [String]
      #   * +rate+ [Avantio::Entities::Rate]
      #   * +availability+ [Avantio::Entities::Availability]
      #   * +rule+ [Avantio::Entities::Rule]
      #   * +length+ [Fixnum] all operations (calc of min_stay, calc of nightly_rate)
      #                       will be in daterange from today to today + length
      def initialize(property_id, rate, availability, rule, length)
        @property_id  = property_id
        @rate         = rate
        @availability = availability
        @rule         = rule
        @length       = length
      end

      # Maps Avantio data to +Roomorama::Calendar+
      def build
        Roomorama::Calendar.new(property_id).tap do |calendar|
          entries = build_entries
          entries.each { |entry| calendar.add(entry) }
        end
      end

      private

      def calendar_start
        Date.today
      end

      def calendar_end
        calendar_start + length
      end

      def fill_availability
        {}.tap do |result|
          availability.actual_periods(length).each do |period|
            from = [calendar_start, period.start_date].max
            to = [calendar_end, period.end_date].min
            available = period.available?
            (from..to).each do |date|
              result[date] = Roomorama::Calendar::Entry.new(
                date:         date.to_s,
                available:    available,
              )
            end
          end
        end
      end

      def fill_rates!(entries)
        rate.actual_periods(length).each do |period|
          from = [calendar_start, period.start_date].max
          to = [calendar_end, period.end_date].min
          (from..to).each do |date|
            entry = entries[date]
            entry.nightly_rate = period.price if entry
          end
        end
      end

      def fill_min_stay_checkin_checkout!(entries)
        rule.actual_seasons(length).each do |season|
          from = [calendar_start, season.start_date].max
          to = [calendar_end, season.end_date].min
          (from..to).each do |date|
            entry = entries[date]
            if entry
              entry.minimum_stay = season.min_nights_online || season.min_nights
              entry.checkin_allowed = season.checkin_allowed(date)
              entry.checkout_allowed = season.checkout_allowed(date)
            end
          end
        end
      end

      def build_entries
        entries = fill_availability
        fill_rates!(entries)
        fill_min_stay_checkin_checkout!(entries)
        entries = entries.values

        # We can't book property without rates, so mark such entries
        # as unavailable
        entries.each do |e|
          unless e.nightly_rate
            e.available = false
            e.nightly_rate = 0
          end
        end

        entries
      end
    end
  end
end
