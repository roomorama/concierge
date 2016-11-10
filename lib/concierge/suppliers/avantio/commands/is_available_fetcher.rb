module Avantio
  module Commands
    # +Avantio::Commands::IsAvailableFetcher+
    #
    # This class is responsible for wrapping the logic related to making a price
    # quotation to Avantio, parsing the response.
    #
    # Usage
    #
    #   command = Avantio::Commands::IsAvailableFetcher.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value # true/false
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates boolean.
    class IsAvailableFetcher

      OPERATION_NAME = :is_available
      AVAILABLE_CODE = '1'
      VALID_RESPONSE_CODES = ['0', '1'] # Not available, Available
      CHECK_IN_TO_NEAR_CODE = '-10'

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def call(params)
        property_id = Avantio::PropertyId.from_roomorama_property_id(params[:property_id])
        message = xml_builder.is_available(property_id, params[:guests], params[:check_in], params[:check_out])
        result = soap_client.call(OPERATION_NAME, message)
        return result unless result.success?

        result_hash = to_safe_hash(result.value)
        return error_result(result_hash) unless valid_result?(result_hash)

        Result.new(available?(result_hash))
      end

      private

      def xml_builder
        @xml_builder ||= Avantio::XMLBuilder.new(credentials)
      end

      def soap_client
        @soap_client ||= Avantio::SoapClient.new
      end

      def valid_result?(result_hash)
        code = fetch_available_code(result_hash)
        code && VALID_RESPONSE_CODES.include?(code)
      end

      def fetch_available_code(result_hash)
        result_hash.get('is_available_rs.available.available_code')
      end

      def fetch_available_message(result_hash)
        result_hash.get('is_available_rs.available.available_message')
      end

      def available?(result_hash)
        fetch_available_code(result_hash) == AVAILABLE_CODE
      end

      def error_result(result_hash)
        code = fetch_available_code(result_hash)
        available_message = fetch_available_message(result_hash)
        message = "Unexpected `is_available` response with code `#{code}` and message `#{available_message}`"
        if code == CHECK_IN_TO_NEAR_CODE
          error_code = :check_in_too_near
        else
          error_code = :unrecognised_response
        end

        mismatch(message, caller)
        Result.error(error_code, message)
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
