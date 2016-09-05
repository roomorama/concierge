module Avantio
  module Entities
    class OccupationalRule
      attr_reader :id, :seasons

      def initialize(id, seasons)
        @id = id
        @seasons = seasons
      end

      def actual_seasons
        from = Date.today
        to = from + 365
        seasons.select do |s|
          s[:min_nights] > 0 &&
            from < s[:end_date] &&
            s[:start_date] <= to
        end
      end

    end
  end
end