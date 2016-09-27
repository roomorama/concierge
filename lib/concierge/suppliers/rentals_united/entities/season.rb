module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::Season+
    #
    # This entity represents a rates season object.
    class Season
      attr_accessor :date_from, :date_to, :price

      def initialize(date_from:, date_to:, price:)
        @date_from = date_from
        @date_to = date_to
        @price = price
      end

      def has_price_for_date?(date)
        date_range.include?(date)
      end

      def number_of_days
        date_range.count
      end

      private
      def date_range
        date_from..date_to
      end
    end
  end
end
