module RentalsUnited
  module Converters
    # +RentalsUnited::Converters::CheckInOutFees+
    #
    # This class converts property's check-in and check-out fee rules to text.
    class CheckInOutFees
      SUPPORTED_LOCALES = %i(en zh de es)
      LATE_ARRIVAL_FEES_TITLE = {
        en: "* Late arrival fees:",
        zh: "* 晚到费用:",
        de: "* Gebühren für späte Ankunft:",
        es: "* Penalización por retraso en la llegada:"
      }
      EARLY_DEPARTURE_FEES_TITLE = {
        en: "* Early departure fees:",
        zh: "* 提早离店费用:",
        de: "* Gebühren für frühe Abreise:",
        es: "* La comisión a aplicar por salida anticipada:"
      }

      # Initialize +RentalsUnited::Converters::CheckInOutFees+
      #
      # Arguments:
      #
      #   * ru_property +RentalsUnited::Entities::Property+
      #   * currency +String+
      def initialize(ru_property, currency)
        @late_arrival_fees    = ru_property.late_arrival_fees
        @early_departure_fees = ru_property.early_departure_fees
        @currency = currency
      end

      # Output hash format:
      #
      # {
      #   en: "en tranlation",
      #   de: "de tranlation",
      #   zh: "zh tranlation",
      #   es: "es tranlation"
      # }
      #
      # Translation for every lang is presented as string in the next format:
      #
      # * Late arrival fees:\n
      #   -  20:00 - 00:00 : $10\n
      #   -  00:00 - 05:00 : $20\n
      #   -  ...
      # * Early departure fees:\n
      #   -  13:00 - 15:00 : $10\n
      #   -  11:00 - 13:00 : $20\n
      #   -  ..
      #
      # If there is no any fees, method returns `nil`
      def build_tranlations
        return nil if empty_fees?

        hash = {}
        SUPPORTED_LOCALES.each { |locale| hash[locale] = localize_fees(locale) }
        hash
      end

      private
      attr_reader :late_arrival_fees, :early_departure_fees, :currency

      def localize_fees(lang)
        [
          formatted_late_arrival_fees(lang),
          formatted_early_departure_fees(lang)
        ].compact.join("\n")
      end

      def empty_fees?
        (late_arrival_fees + early_departure_fees).empty?
      end

      def formatted_late_arrival_fees(lang)
        return nil unless late_arrival_fees.any?

        [
          LATE_ARRIVAL_FEES_TITLE[lang],
          formatted_rules(late_arrival_fees)
        ].join("\n")
      end

      def formatted_early_departure_fees(lang)
        return nil unless early_departure_fees.any?

        [
          EARLY_DEPARTURE_FEES_TITLE[lang],
          formatted_rules(early_departure_fees)
        ].join("\n")
      end

      def formatted_rules(rules)
        rules.sort { |r| r[:amount] }.map do |rule|
          "-  #{rule[:from]} - #{rule[:to]} : #{rule[:amount]} #{currency}"
        end.join("\n")
      end
    end
  end
end
