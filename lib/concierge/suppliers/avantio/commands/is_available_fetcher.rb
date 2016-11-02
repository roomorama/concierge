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
        return error_result unless valid_result?(result_hash)

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
        !!fetch_available_code(result_hash)
      end

      def fetch_available_code(result_hash)
        result_hash.get('is_available_rs.available.available_code')
      end

      def available?(result_hash)
        fetch_available_code(result_hash) == AVAILABLE_CODE
      end

      def error_result
        message = 'Unexpected `is_available` response structure'
        mismatch(message, caller)
        Result.error(
          :unexpected_response_structure,
          message
        )
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
