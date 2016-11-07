module THH
  module Commands
    #  +THH::Commands::Booking+
    #
    # This class is responsible for wrapping the logic related to
    # making a THH booking.
    #
    # Usage
    #
    #   command = THH::Commands::Booking.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value['booking_id'] # reservation id
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +Hash+.
    class Booking < BaseFetcher
      ROOMORAMA_DATE_FORMAT = '%Y-%m-%d'
      THH_DATE_FORMAT = '%d/%m/%Y'
      VILLA_STATUS = 'response.villa_status'
      BOOKING_STATUS = 'response.booking_status'
      BOOKING_ID = 'response.booking_id'


      def call(params)
        result = api_call(params(params))
        return result unless result.success?

        response = Concierge::SafeAccessHash.new(result.value)
        result = validate_response(response, params)
        return result unless result.success?

        Result.new(response['response'])
      end

      protected

      def action
        'book'
      end

      private

      def validate_response(response, params)
        villa_status = response.get(VILLA_STATUS)
        unless villa_status
          return Result.error(
            :unrecognised_response,
            "Booking response for params `#{params.to_h}` does not contain `#{VILLA_STATUS}` field")
        end
        # Possible values for villa status: on_request, instant, not_available
        if villa_status != 'instant'
          return Result.error(
            :unrecognised_response,
            "Booking response for params `#{params.to_h}` contains unexpected value for `#{VILLA_STATUS}` field: `#{villa_status}`")
        end

        booking_status = response.get(BOOKING_STATUS)
        if booking_status.nil?
          return Result.error(
            :unrecognised_response,
            "Booking response for params `#{params.to_h}` does not contain `#{BOOKING_STATUS}` field")
        end
        # Possible values for booking status: success, false
        if booking_status != 'success'
          return Result.error(
            :unrecognised_response,
            "Booking response for params `#{params.to_h}` contains unexpected value for `#{BOOKING_STATUS}` field: `#{booking_status}`")
        end

        booking_id = response.get(BOOKING_ID)
        unless booking_id
          return Result.error(
            :unrecognised_response,
            "Booking response for params `#{params.to_h}` does not contain `#{BOOKING_ID}` field")
        end

        Result.new(true)
      end

      def params(params)
        {
          'id'        => params[:property_id],
          'arrival'   => convert_date(params[:check_in]),
          'departure' => convert_date(params[:check_out]),
          'curr'      => THH::Commands::PropertiesFetcher::CURRENCY,
          'firstname' => params[:customer][:first_name],
          'lastname'  => params[:customer][:last_name],
          'phone'     => params[:customer][:phone] || '',
          'mail'      => params[:customer][:email],
          'country'   => params[:customer][:country] || '',
          'adults'    => params[:guests],
          'children'  => '',
          'infants'   => ''
        }
      end

      # Converts date string to THH expected format
      def convert_date(date)
        Date.strptime(date, ROOMORAMA_DATE_FORMAT).strftime(THH_DATE_FORMAT)
      end
    end
  end
end
