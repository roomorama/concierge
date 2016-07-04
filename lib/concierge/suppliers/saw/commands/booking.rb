module SAW
  module Commands
    # +SAW::Commands::Booking+
    #
    # This class is responsible for wrapping the logic related to making a
    # reservation to SAW, parsing the response, and building the +Reservation+
    # object with the data returned from their API.
    #
    # Usage
    #
    #   command = SAW::Commands::Booking.new(credentials)
    #   result = command.call(reservation_params)
    #
    #   if result.success?
    #     process_reservation(result.value)
    #   else
    #     handle_error(result.error)
    #   end
    class Booking < BaseFetcher
      # Calls the SAW API method usung the HTTP client.
      #
      # Arguments
      #
      #   * +params+ [Concierge::SafeAccessHash] reservation parameters
      #
      # Reservation parameters are defined by the set of attributes from
      # +API::Controllers::Params::MultiUnitBooking+ params object.
      #
      # +params+ object includes:
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
      def call(params)
        payload = build_payload(params)
        result = http.post(endpoint(:property_booking), payload, content_type)

        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            reservation = SAW::Mappers::Reservation.build(params, result_hash)
            
            Result.new(reservation)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      private
      def build_payload(params)
        payload_builder.build_booking_request(
          property_id:   params.get("property_id"),
          unit_id:       params.get("unit_id"),
          currency_code: params.get("currency_code"),
          check_in:      params.get("check_in"),
          check_out:     params.get("check_out"),
          num_guests:    params.get("guests"),
          total:         params.get("subtotal"),
          user: {
            first_name:  params.get("customer.first_name"),
            last_name:   params.get("customer.last_name"),
            email:       params.get("customer.email")
          }
        )
      end
    end
  end
end
