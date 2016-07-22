module SAW
  module Mappers
    # +SAW::Mappers::Reservation+
    #
    # This class is responsible for building a +Reservation+ 
    # object from the hash which was fetched from the SAW API.
    class Reservation
      # Builds a property
      #
      # Arguments:
      #
      #   * +request_params+ [Concierge::SafeAccessHash] reservation attributes
      #   * +result_hash+ [Concierge::SafeAccessHash] hash with reservation
      #                                               number
      #
      # Returns [Reservation]
      def self.build(request_params, result_hash)
        reservation_code = parse_reservation_code(result_hash)

        ::Reservation.new(
          request_params.to_h.merge!(reference_number: reservation_code)
        )
      end

      private
      def self.parse_reservation_code(hash)
        hash.get("response.booking_ref_number")
      end
    end
  end
end
