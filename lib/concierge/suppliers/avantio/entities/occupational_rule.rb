module Avantio
  module Entities
    class OccupationalRule
      class Season
        attr_reader :start_date, :end_date, :min_nights, :min_nights_online,
                    :checkin_days, :checkin_weekdays, :checkout_days, :checkout_weekdays

        def initialize(start_date, end_date, min_nights, min_nights_online, checkin_days,
                       checkin_weekdays, checkout_days, checkout_weekdays)
          @start_date        = start_date
          @end_date          = end_date
          @min_nights        = min_nights
          @min_nights_online = min_nights_online
          @checkin_days      = checkin_days
          @checkin_weekdays  = checkin_weekdays
          @checkout_days     = checkout_days
          @checkout_weekdays = checkout_weekdays
        end

        # Returns true, false, or nil if can't determine
        def checkin_allowed(date)
          include_check(date, checkin_weekdays, checkin_days)
        end

        # Returns true, false, or nil if can't determine
        def checkout_allowed(date)
          include_check(date, checkout_weekdays, checkout_days)
        end

        def include?(date)
          start_date <= date && date <= end_date
        end

        private

        def include_check(date, weekdays, days)
          return unless include?(date)

          weekdays_check = weekdays.include?(weekday(date)) unless weekdays.empty?
          days_check = days.include?(monthday(date)) unless days.empty?

          [weekdays_check, days_check].compact.inject { |x, y| x && y }
        end

        def weekday(date)
          date.strftime('%^A')
        end

        def monthday(date)
          date.strftime('%-d')
        end
      end

      attr_reader :id, :seasons

      def initialize(id, seasons)
        @id = id
        @seasons = seasons
      end

      # Returns min nights among all actual seasons
      def min_nights(length)
        actual_seasons(length).map do |season|
          season.min_nights_online || season.min_nights
        end.min
      end

      # Returns seasons which have min_nights > 0 and have intersection with [today, today + length]
      def actual_seasons(length)
        from = Date.today
        to = from + length
        seasons.select do |s|
          (s.min_nights.to_i > 0 || s.min_nights_online.to_i > 0) &&
            from < s.end_date &&
            s.start_date <= to
        end
      end
    end
  end
end