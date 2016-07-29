module Woori
  module Entities
    # +Woori::Entities::ReservationStatus+
    #
    # This entity represents a reservation object status
    #
    # Attributes
    #
    # +reservation_code+ - reservation unique hash
    # +status+           - status (pending, confirmed)
    class ReservationStatus
      attr_reader :reservation_code, :status

      def initialize(reservation_code:, status:)
        @reservation_code = reservation_code
        @status           = status
      end
    end
  end
end
