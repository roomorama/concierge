module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Rate+
    #
    # This class is responsible for building a rate object.
    class Rate
      attr_reader :hash

      # Initialize +RentalsUnited::Mappers::Rate+.
      #
      # Arguments
      #   * +hash+ rate object hash
      #
      # Usage
      #
      #   RentalsUnited::Mappers::Rate.new({
      #     "Price"=>"200.0000",
      #     "Extra"=>"10.0000",
      #     "@DateFrom"=>"2016-09-07",
      #     "@DateTo"=>"2016-09-30"
      #   })
      def initialize(hash)
        @hash = hash
      end

      def build_rate
        Entities::Rate.new(
          date_from: Date.parse(hash["@DateFrom"]),
          date_to:   Date.parse(hash["@DateTo"]),
          price:     hash["Price"]
        )
      end
    end
  end
end
