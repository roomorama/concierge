module Woori
  module Mappers
    # +Woori::Mappers::UnitRates+
    #
    # This class is responsible for building a +Entities::UnitRates+ object.
    class UnitRates
      attr_reader :safe_hash

      # Initialize UnitRates mapper
      #
      # Arguments:
      #
      #   * +safe_hash+ [Concierge::SafeAccessHash] unit rate parameters
      def initialize(safe_hash)
        @safe_hash = safe_hash
      end

      # Builds Roomorama::Unit object
      #
      # Usage:
      #
      #   Mappers::UnitRates.build(safe_hash)
      #
      # Returns +Entities::UnitRates+ Unit rates object
      def build
        return nil unless days && days.any?
     
        Entities::UnitRates.new(
          nightly_rate: nightly_rate,
          weekly_rate:  weekly_rate,
          monthly_rate: monthly_rate
        )
      end

      private
      def days
        safe_hash.get("data")
      end

      def nightly_rate
        (monthly_rate / 30).to_i
      end

      def weekly_rate
        nightly_rate * 7 
      end

      def monthly_rate
        days.inject(0) { |sum, day| sum + day["price"].to_i }
      end
    end
  end
end
