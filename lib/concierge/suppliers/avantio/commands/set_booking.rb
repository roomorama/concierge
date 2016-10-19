module Avantio
  module Commands
    # +Avantio::Commands::SetBooking+
    #
    # This class is responsible for wrapping the logic related to making
    # an Avantio booking, parsing the response.
    #
    #  NOTE: Avantio SetBooking method can return valid response even
    #  if accommodation is not available for given period, so it's important
    #  to check availability before using this command.
    #
    # Usage
    #
    #   command = Avantio::Commands::SetBooking.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +::Reservation+.
    class SetBooking

      OPERATION_NAME = :set_booking

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def call(params)
        property_id = Avantio::PropertyId.from_roomorama_property_id(params[:property_id])
        customer = params[:customer]
        message = xml_builder.set_booking(
          property_id, params[:guests], params[:check_in],
          params[:check_out], customer, credentials.test)

        result = soap_client.call(OPERATION_NAME, message)
        return result unless result.success?

        result_hash = to_safe_hash(result.value)
        return error_result(result_hash) unless valid_result?(result_hash)

        reservation = mapper.build(params, result_hash)

        Result.new(reservation)
      end

      private

      def xml_builder
        @xml_builder ||= Avantio::XMLBuilder.new(credentials)
      end

      def mapper
        @mapper ||= Avantio::Mappers::RoomoramaReservation.new
      end

      def soap_client
        @soap_client ||= Avantio::SoapClient.new
      end

      def valid_result?(result_hash)
        success = fetch_success(result_hash)
        booking_code = fetch_booking_code(result_hash)
        # Valid if success and booking_code isn't empty
        success && !booking_code.to_s.empty?
      end

      def error_result(result_hash)
        errors = {
          Success:  fetch_success(result_hash),
          BookingCode: fetch_booking_code(result_hash),
          ErrorList: fetch_error_list_as_string(result_hash)
        }

        parts = ['The `set_booking` response contains unexpected data.']
        errors.each do |label, field|
          unless field.nil?
            parts << "#{label}: `#{field}`"
          end
        end
        message = parts.join("\n")

        mismatch(message, caller)
        Result.error(:unexpected_response, message)
      end

      def fetch_success(result_hash)
        result_hash.get('set_booking_rs.success')
      end

      def fetch_booking_code(result_hash)
        result_hash.get('set_booking_rs.localizer.booking_code')
      end

      def fetch_error_list_as_string(result_hash)
        error_list = result_hash.get('set_booking_rs.error_list.error')
        if error_list
          Array(error_list).map do |error|
            "ErrorId: #{error[:error_id]}, ErrorMessage: #{error[:error_message]}"
          end.join("\n")
        end
      end

      def to_safe_hash(hash)
        Concierge::SafeAccessHash.new(hash)
      end

      def mismatch(message, backtrace)
        response_mismatch = Concierge::Context::ResponseMismatch.new(
          message:   message,
          backtrace: backtrace
        )

        Concierge.context.augment(response_mismatch)
      end
    end
  end
end
