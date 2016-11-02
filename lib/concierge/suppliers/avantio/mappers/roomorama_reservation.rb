module Avantio
  module Mappers
    class RoomoramaReservation
      # Maps hash representation of Avantio API SetBooking response
      # to Reservation
      def build(params, hash)
        reservation = ::Reservation.new(params)
        reservation.reference_number = parse_reference_number(hash)
        reservation
      end

      private

      def parse_reference_number(hash)
        hash.get('set_booking_rs.localizer.booking_code')
      end
    end
  end
end
