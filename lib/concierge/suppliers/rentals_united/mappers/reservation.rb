module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Reservation+
    #
    # This class is responsible for building a +Reservation+ object
    class Reservation
      attr_reader :reservation_code, :reservation_params

      # Initialize Reservation mapper
      #
      # Arguments:
      #
      #   * +reservation_code+ [String] reservation code
      #   * +reservation_params+ [Concierge::SafeAccessHash] parameters
      def initialize(reservation_code, reservation_params)
        @reservation_code = reservation_code
        @reservation_params = reservation_params
      end

      # Builds reservation
      #
      # Returns [Reservation]
      def build_reservation
        ::Reservation.new(
          reservation_params.to_h.merge!(
            reference_number: reservation_code
          )
        )
      end
    end
  end
end
