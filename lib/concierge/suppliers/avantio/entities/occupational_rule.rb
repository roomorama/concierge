module Avantio
  module Entities
    class OccupationalRule
      # Count of days
      PERIOD_LENGTH = 365

      attr_reader :id, :seasons

      def initialize(id, seasons)
        @id = id
        @seasons = Array(seasons)
      end

      def actual_seasons
        from = Date.today
        to = from + PERIOD_LENGTH
        seasons.select do |s|
          s[:min_nights] > 0 &&
            from < s[:end_date] &&
            s[:start_date] <= to
        end
      end

    end
  end
end