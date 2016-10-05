module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Season+
    #
    # This class is responsible for building a season object.
    class Season
      attr_reader :hash

      # Initialize +RentalsUnited::Mappers::Season+.
      #
      # Arguments
      #   * +hash+ season object hash
      #
      # Usage
      #
      #   RentalsUnited::Mappers::Season.new({
      #     "Price"=>"200.0000",
      #     "Extra"=>"10.0000",
      #     "@DateFrom"=>"2016-09-07",
      #     "@DateTo"=>"2016-09-30"
      #   })
      def initialize(hash)
        @hash = hash
      end

      def build_season
        Entities::Season.new(
          date_from: Date.parse(hash["@DateFrom"]),
          date_to:   Date.parse(hash["@DateTo"]),
          price:     hash["Price"].to_f
        )
      end
    end
  end
end
