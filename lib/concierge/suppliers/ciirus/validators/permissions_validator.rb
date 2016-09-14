module Ciirus
  module Validators
    # +Ciirus::Validators::PermissionsValidator+
    #
    # This class responsible for properties validation.
    # cases when property permissions invalid:
    #
    #   * online booking is not allowed
    #   * property is timeshare (as well as GetReservations method doesn't support such properties)
    #   * properties with AOA(Allocation On Arrival) Bookings Mode
    #   * property deleted
    #
    class PermissionsValidator
      attr_reader :permissions

      def initialize(permissions)
        @permissions = permissions
      end

      def valid?
        online_booking_allowed? &&
          !timeshare? &&
          !allocation_on_arrival? &&
          !property_deleted?
      end

      private

      def online_booking_allowed?
        permissions.online_booking_allowed
      end

      def timeshare?
        permissions.time_share
      end

      def allocation_on_arrival?
        permissions.aoa_property
      end

      def property_deleted?
        permissions.deleted
      end
    end
  end
end
