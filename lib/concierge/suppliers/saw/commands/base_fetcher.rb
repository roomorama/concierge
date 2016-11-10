module SAW
  module Commands
    class BaseFetcher
      # Some errors from SAW API are not actually errors, so this constant is
      # a list of whitelisted codes, which we consider as normal behaviour.
      #
      # Whitelisted SAW API errors:
      # 1007 - No properties are available for the given search parameters
      # 3031 - Rates are not available for this property
      VALID_RESULT_ERROR_CODES = ['1007', '3031']

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def endpoint(name)
        SAW::Endpoint.endpoint_for(name)
      end

      def payload_builder
        @payload_builder ||= SAW::PayloadBuilder.new(credentials)
      end

      def response_parser
        @response_parser ||= SAW::ResponseParser.new
      end

      def http
        @http_client ||= Concierge::HTTPClient.new(credentials.url, timeout: 20)
      end

      def content_type
        { "Content-Type" => "application/xml" }
      end

      def valid_result?(hash)
        if hash.get("response")
          return true if hash.get("response.errors").nil?

          code = hash.get("response.errors.error.code")
          VALID_RESULT_ERROR_CODES.include?(code)
        else
          false
        end
      end

      def error_result(parsed_hash, original_response)
        saw_code = parsed_hash.get("response.errors.error.code")
        saw_description = parsed_hash.get("response.errors.error.description")

        if saw_code && saw_description
          message = "Response indicating the error `#{saw_code}`, and description `#{saw_description}`"
          unrecognised_response_error(message)
        else
          message = "Error response could not be recognised (no `code` or `description` fields). "
          message += "Original response: `#{original_response}`"
          unrecognised_response_error(message)
        end
      end

      def unrecognised_response_error(message)
        mismatch(message, caller)
        Result.error(:unrecognised_response, message)
      end

      def mismatch(message, backtrace)
        response_mismatch = Concierge::Context::ResponseMismatch.new(
          message: message,
          backtrace: backtrace
        )

        Concierge.context.augment(response_mismatch)
      end
    end
  end
end
