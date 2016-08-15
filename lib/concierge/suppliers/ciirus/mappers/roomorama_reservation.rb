module Ciirus
  module Mappers
    class RoomoramaReservation
      # Maps hash representation of Ciirus API MakeBooking response
      # to Reservation
      def build(params, hash)
        reservation = ::Reservation.new(params)
        reservation.reference_number = parse_reservation_code(hash)
        reservation
      end

      private

      def parse_reservation_code(hash)
        hash.get('make_booking_response.make_booking_result.booking_id')
      end
    end
  end
end
