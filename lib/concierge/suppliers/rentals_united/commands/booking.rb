module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::Booking+
    #
    # This class is responsible for wrapping the logic related to making a
    # reservation to RentalsUnited, parsing the response, and building the
    # +Reservation+ object with the data returned from their API.
    #
    # Usage
    #
    #   command = RentalsUnited::Commands::Booking.new(credentials, params)
    #   result = command.call
    #
    #   if result.success?
    #     process_reservation(result.value)
    #   else
    #     handle_error(result.error)
    #   end
    class Booking < BaseFetcher
      attr_reader :reservation_params

      ROOT_TAG = "Push_PutConfirmedReservationMulti_RS"

      # Initialize +Booking+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +reservation_params+ [Concierge::SafeAccessHash] stay parameters
      #
      # Stay parameters are defined by the set of attributes from
      # +API::Controllers::Params::Booking+ params object.
      #
      # +reservation_params+ object includes:
      #
      #   * +property_id+
      #   * +check_in+
      #   * +check_out+
      #   * +guests+
      def initialize(credentials, reservation_params)
        super(credentials)
        @reservation_params = reservation_params
      end

      # Calls the RentalsUnited API method using the HTTP client.
      #
      # Returns a +Result+ wrapping a +Reservation+ when operation succeeds
      # Returns a +Result+ with +Result::Error+ when operation fails
      def call
        payload = build_payload
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_reservation(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_payload
        payload_builder.build_booking_payload(
          property_id: reservation_params.get("property_id"),
          check_in:    reservation_params.get("check_in"),
          check_out:   reservation_params.get("check_out"),
          num_guests:  reservation_params.get("guests"),
          total:       reservation_params.get("subtotal"),
          user: {
            first_name:  reservation_params.get("customer.first_name"),
            last_name:   reservation_params.get("customer.last_name"),
            email:       reservation_params.get("customer.email"),
            phone:       reservation_params.get("customer.phone"),
            address:     reservation_params.get("customer.address"),
            postal_code: reservation_params.get("customer.postal_code")
          }
        )
      end

      def build_reservation(result_hash)
        reservation_code = result_hash.get("#{ROOT_TAG}.ReservationID")

        mapper = Mappers::Reservation.new(reservation_code, reservation_params)
        mapper.build_reservation
      end
    end
  end
end
