module Ciirus
  module Commands
    # +Ciirus::Commands::Booking+
    #
    # This class is responsible for wrapping the logic related to making
    # a Ciirus booking, parsing the response, and building the +Reservation+ object
    # with the data returned from their API.
    #
    # Usage
    #
    #   command = Ciirus::Commands::Booking.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value # Reservation instance
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +Reservation+.
    class Booking < BaseCommand

      def call(params)
        customer = params[:customer]
        name = "#{customer[:first_name]} #{customer[:last_name]}"
        email = customer[:email]
        phone = customer[:phone]
        address = customer[:address]
        guest = Ciirus::BookingGuest.new(name, email, address, phone)

        arrival_date = convert_date(params[:check_in])
        departure_date = convert_date(params[:check_out])
        message = xml_builder.make_booking(params[:property_id],
                                           arrival_date,
                                           departure_date,
                                           guest)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          if valid_result?(result_hash)
            reservation = Ciirus::Mappers::RoomoramaReservation.build(params, result_hash)
            Result.new(reservation)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      protected

      def valid_result?(result_hash)
        booking_placed = extract_booking_placed(result_hash)
        error_msg = extract_error_message(result_hash)
        # Valid if booking placed and error_msg is empty
        booking_placed && (error_msg.nil? || error_msg.empty?)
      end

      def operation_name
        :make_booking
      end

      def error_result(result_hash)
        booking_placed = extract_booking_placed(result_hash)
        description = extract_error_message(result_hash)
        message = "The response contains unexpected data:
                   ErrorMessage: #{description};
                   BookingPlaced: #{booking_placed}"
        mismatch(message, caller)
        Result.error(:unexpected_response)
      end

      private

      def extract_error_message(result_hash)
        result_hash.get('make_booking_response.make_booking_result.error_message')
      end

      def extract_booking_placed(result_hash)
        result_hash.get('make_booking_response.make_booking_result.booking_placed')
      end
    end
  end
end
