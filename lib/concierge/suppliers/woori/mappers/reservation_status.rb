module Woori
  module Mappers
    # +Woori::Mappers::ReservationStatus+
    #
    # This class is responsible for building an object for representing
    # the status of the reservation (pending, confirmed, etc)
    class ReservationStatus
      attr_reader :safe_hash

      # Initialize ReservationStatus mapper
      #
      # Arguments:
      #
      #   * +safe_hash+ [Concierge::SafeAccessHash] reservation attributes
      def initialize(safe_hash)
        @safe_hash = safe_hash
      end

      # Builds a reservation status object
      #
      # Returns +Woori::Entities::ReservationStatus+ status object
      def build_reservation_status
        Entities::ReservationStatus.new(
          reservation_code: safe_hash.get("hash"),
          status:           safe_hash.get("data.status")
        )
      end
    end
  end
end
