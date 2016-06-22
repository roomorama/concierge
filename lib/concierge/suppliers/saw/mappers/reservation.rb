module SAW
  module Mappers
    class Reservation
      def self.build(request_params, result_hash)
        reservation_code = parse_reservation_code(result_hash)

        ::Reservation.new(request_params.merge!(code: reservation_code))
      end

      private
      def self.parse_reservation_code(hash)
        hash.get("response.booking_ref_number")
      end
    end
  end
end
