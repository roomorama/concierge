module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Availability+
    #
    # This class is responsible for building an availability object.
    class Availability
      attr_reader :hash

      def initialize(hash)
        @hash = hash
      end

      def build_availability
        Entities::Availability.new(
          date:         Date.parse(hash["@Date"]),
          available:    hash["IsBlocked"] == false,
          minimum_stay: hash["MinStay"].to_i,
          changeover:   hash["Changeover"].to_i
        )
      end
    end
  end
end
