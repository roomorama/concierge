module Avantio
  module Entities
    class OccupationalRule
      Season = Struct.new(:start_date, :end_date, :min_nights, :min_nights_online)

      attr_reader :id, :seasons

      def initialize(id, seasons_array)
        @id = id
        @seasons = build_seasons(seasons_array)
      end

      # Returns min nights among all actual seasons
      def min_nights(length)
        actual_seasons(length).map do |season|
          season.min_nights_online || season.min_nights
        end.min
      end

      private

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

      def build_seasons(seasons_array)
        seasons_array.map { |s| Season.new(s[:start_date], s[:end_date], s[:min_nights], s[:min_nights_online]) }
      end
    end
  end
end