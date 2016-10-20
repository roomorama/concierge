module RentalsUnited
  module Converters
    # +RentalsUnited::Converters::CheckInOutFees+
    #
    # This class converts property's check-in and check-out fee rules to text.
    class CheckInOutFees
      LATE_ARRIVAL_FEES_TITLE    = "* Late arrival fees:"
      EARLY_DEPARTURE_FEES_TITLE = "* Early departure fees:"

      # Initialize +RentalsUnited::Converters::CheckInOutFees+
      #
      # Arguments:
      #
      #   * ru_property +RentalsUnited::Entities::Property+
      def initialize(ru_property)
        @late_arrival_fees    = ru_property.late_arrival_fees
        @early_departure_fees = ru_property.early_departure_fees
      end

      # Output format:
      # * Late arrival fees:\n
      #   -  20:00 - 00:00 : $10\n
      #   -  00:00 - 05:00 : $20\n
      #   -  ...
      # * Early departure fees:\n
      #   -  13:00 - 15:00 : $10\n
      #   -  11:00 - 13:00 : $20\n
      #   -  ..
      def as_text
        return nil if empty_fees?

        [
          formatted_late_arrival_fees,
          formatted_early_departure_fees
        ].compact.join("\n")
      end

      private
      attr_reader :late_arrival_fees, :early_departure_fees

      def empty_fees?
        (late_arrival_fees + early_departure_fees).empty?
      end

      def formatted_late_arrival_fees
        return nil unless late_arrival_fees.any?

        [
          LATE_ARRIVAL_FEES_TITLE,
          formatted_rules(late_arrival_fees)
        ].join("\n")
      end

      def formatted_early_departure_fees
        return nil unless early_departure_fees.any?

        [
          EARLY_DEPARTURE_FEES_TITLE,
          formatted_rules(early_departure_fees)
        ].join("\n")
      end

      def formatted_rules(rules)
        rules.sort { |r| r[:amount] }.map do |rule|
          "-  #{rule[:from]} - #{rule[:to]} : #{rule[:amount]}"
        end.join("\n")
      end
    end
  end
end
