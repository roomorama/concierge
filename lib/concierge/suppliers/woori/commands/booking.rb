module Woori
  module Commands
    # +Woori::Commands::Booking+
    #
    # This class is responsible for wrapping the logic related to making a
    # reservation to Woori, parsing the response, and building the
    # +Reservation+ object with the data returned from their API.
    #
    # Usage
    #
    #   command = Woori::Commands::Booking.new(credentials)
    #   result = command.call(reservation_params)
    #
    #   if result.success?
    #     process_reservation(result.value)
    #   else
    #     handle_error(result.error)
    #   end
    class Booking < BaseFetcher
      include Concierge::JSON

      ENDPOINT = "reservation/confirm"

      # Calls the Woori API method usung the HTTP client.
      #
      # Arguments
      #
      #   * +reservation_params+ [Concierge::SafeAccessHash]
      #
      # Reservation parameters are defined by the set of attributes from
      # +API::Controllers::Params::MultiUnitBooking+ params object.
      #
      # +reservation_params+ object includes:
      #
      #   * +property_id+
      #   * +unit_id+
      #   * +check_in+
      #   * +check_out+
      #   * +guests+
      #   * +subtotal+
      #   * +customer+
      #
      # +customer+ object includes:
      #
      #   * +first_name+
      #   * +last_name+
      #   * +email+
      #
      # The +call+ method returns a +Result+ object that, when successful,
      # encapsulates the resulting +Reservation+ object.
      def call(reservation_params)
        params = build_confirm_request_params(reservation_params)
        result = http.post(ENDPOINT, params, headers)

        if result.success?
          decoded_result = json_decode(result.value.body)

          if decoded_result.success?
            safe_hash = Concierge::SafeAccessHash.new(decoded_result.value)
            mapper = Woori::Mappers::Reservation.new(reservation_params, safe_hash.get("data"))
            reservation = mapper.build_reservation

            Result.new(reservation)
          else
            decoded_result
          end
        else
          result
        end
      end

      def build_confirm_request_params(reservation_params)
        json_encode(
          roomtypeCode:  reservation_params.get("unit_id"),
          checkInDate:   format_date(reservation_params.get("check_in")),
          checkOutDate:  format_date(reservation_params.get("check_out")),
          guestName:     full_name(reservation_params.get("customer")),
          guestCount:    reservation_params.get("guests"),
          adultCount:    reservation_params.get("guests"),
          childrenCount: 0,
          paidPrice:     reservation_params.get("subtotal"),
          currency:      reservation_params.get("currency_code")
        )
      end

      def format_date(date)
        Date.parse(date).strftime("%Y-%m-%d")
      end

      def full_name(customer)
        first_name = customer.get("first_name")
        last_name  = customer.get("last_name")

        [first_name, last_name].join(' ')
      end
    end
  end
end
