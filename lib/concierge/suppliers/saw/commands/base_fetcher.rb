module SAW
  module Commands
    class BaseFetcher
      # Some errors from SAW API are not actually errors, so this constant is
      # a list of whitelisted codes, which we consider as normal behaviour.
      VALID_RESULT_ERROR_CODES = ['1007']

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

      def error_result(hash)
        code = hash.get("response.errors.error.code")
        description = hash.get("response.errors.error.description")

        if code && description
          augment_with_error(code, description, caller)
          Result.error(code)
        else
          unrecognised_response_event(caller)
          Result.error(:unrecognised_response)
        end
      end

      def augment_with_error(code, description, backtrace)
        message = "Response indicating the error `#{code}`, and description `#{description}`"
        mismatch(message, backtrace)
      end

      def unrecognised_response_event(backtrace)
        message = "Error response could not be recognised (no `code` or `description` fields)."
        mismatch(message, backtrace)
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
