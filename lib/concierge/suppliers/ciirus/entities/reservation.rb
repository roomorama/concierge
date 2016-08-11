module Ciirus
  module Entities
    class Reservation
      attr_reader :arrival_date, :departure_date, :booking_id, :has_pool_heat, :guest_name

      def initialize(arrival_date, departure_date, booking_id, has_pool_heat, guest_name)
        @arrival_date   = arrival_date
        @departure_date = departure_date
        @booking_id     = booking_id
        @has_pool_heat  = has_pool_heat
        @guest_name     = guest_name
      end

      def ==(other)
        self.class == other.class && state == other.state
      end

      protected

      def state
        [arrival_date, departure_date, booking_id, has_pool_heat, guest_name]
      end
    end
  end
end