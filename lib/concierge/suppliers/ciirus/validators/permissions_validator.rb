module Ciirus
  module Validators
    # +Ciirus::Validators::PermissionsValidator+
    #
    # This class responsible for properties validation.
    # cases when property permissions invalid:
    #
    #   * online booking is not allowed
    #   * property is timeshare (as well as GetReservations method doesn't support such properties)
    #
    class PermissionsValidator
      attr_reader :permissions

      def initialize(permissions)
        @permissions = permissions
      end

      def valid?
        online_booking_allowed? && !timeshare?
      end

      private

      def online_booking_allowed?
        permissions.online_booking_allowed
      end

      def timeshare?
        permissions.time_share
      end
    end
  end
end
