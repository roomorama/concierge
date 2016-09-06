module Poplidays
  module Commands
    # +Poplidays::Commands::Booking+
    #
    # This class is responsible for wrapping the logic related to
    # making a Poplidays booking.
    #
    # It uses bookings/easy API endpoint with "requestType":"BOOKED" parameter.
    #
    # Usage
    #
    #   command = Poplidays::Commands::Booking.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value['id'] # reservation id
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +Hash+.
    class Booking < BaseCommand

      PATH = 'bookings/easy'

      def call(params)
        raw_booking = remote_call(params: request_json(params))
        if raw_booking.success?
          json_decode(raw_booking.value)
        else
          raw_booking
        end
      end

      protected

      def path
        PATH
      end

      def authentication
        with_authentication
      end

      def method
        :post
      end

      private

      def mapper
        @mapper ||= Poplidays::Mappers::Quote.new
      end

      # All the fields here (inside customer and address too) are required for Poplidays.
      # Not all fields exists in Roomorama webhook params, but
      # my test booking in the Poplidays' sandbox shows that empty values here are also valid.
      def request_json(params)
        {
          'requestType'   => 'BOOKED',
          'lodgingId'     => params[:property_id],
          'arrival'       => convert_date(params[:check_in]),
          'departure'     => convert_date(params[:check_out]),
          'occupantCount' => params[:guests],
          'price'         => params[:subtotal],
          'customer'      => customer(params[:customer]),
        }
      end

      def customer(customer_params)
        {
          'address'     => address(customer_params),
          'email'       => customer_params[:email],
          'firstName'   => customer_params[:first_name],
          'lastName'    => customer_params[:last_name],
          'language'    => customer_params[:language] || '',
          'phoneNumber' => customer_params[:phone] || '',
          'civility'    => civility(customer_params[:gender])
        }
      end

      # Actually Poplidays waits "MISTER_AND_MADAM", "MISTER", "MADAM" or "COMPANY"
      # but while gender param is always empty, we cannot determine the civility.
      def civility(gender)
        ''
      end

      def address(customer_params)
        {
          'line1'      => customer_params[:address] || '',
          'city'       => customer_params[:city] || '',
          'country'    => customer_params[:country] || '',
          'postalCode' => customer_params[:postal_code] || ''
        }
      end
    end
  end
end
