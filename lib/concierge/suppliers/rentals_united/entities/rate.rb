module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::Rate+
    #
    # This entity represents an rate object.
    class Rate
      attr_accessor :date_from, :date_to, :price

      def initialize(date_from:, date_to:, price:)
        @date_from = date_from
        @date_to = date_to
        @price = price
      end

      def has_price_for_date?(date)
        (date_from..date_to).include?(date)
      end
    end
  end
end
