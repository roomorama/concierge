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

      def build_entries
        index.map do |date, data|
          availability_period = data[:availability_period]
          rate_period = data[:rate_period]
          rule_season = data[:rule_season]
          # Avantio doesn't allow to book if at least one of these
          # not determine for the date, so mark it as unavailable
          if availability_period && rate_period && rule_season
            Roomorama::Calendar::Entry.new(
              date:             date.to_s,
              available:        availability_period.available?,
              nightly_rate:     rate_period.price,
              minimum_stay:     rule_season.min_nights,
              checkin_allowed:  rule_season.checkin_allowed(date),
              checkout_allowed: rule_season.checkout_allowed(date)
            )
          else
            Roomorama::Calendar::Entry.new(
              date:         date.to_s,
              available:    false,
              nightly_rate: 0
            )
          end
        end
      end

      # For each date we want to put in calendar returns first found availability, rate and rule
      # Returns Hash.
      #
      # {
      #   date1 => {
      #     availability_period: availability_period,
      #     rate_period: rate_period,
      #     rule_season: rule_season
      #   },
      #   date2 => {
      #     availability_period: availability_period,
      #     rate_period: nil,
      #     rule_season: rule_season
      #   }
      # }
      def index
        (calendar_start..calendar_end).map do |date|
          availability_period = availability.actual_periods(length).detect { |p| p.include?(date) }
          rate_period = rate.actual_periods(length).detect { |p| p.include?(date) }
          rule_season = rule.actual_seasons(length).detect { |s| s.include?(date) }
          [
            date,
            {
              availability_period: availability_period,
              rate_period: rate_period,
              rule_season: rule_season
            }
          ]
        end.to_h
      end
    end
  end
end
