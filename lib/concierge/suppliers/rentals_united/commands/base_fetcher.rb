module RentalsUnited
  module Commands
    class BaseFetcher
      attr_reader :credentials

      VALID_RU_STATUS_CODES = ["0"]

      def initialize(credentials)
        @credentials = credentials
      end

      def payload_builder
        @payload_builder ||= RentalsUnited::PayloadBuilder.new(credentials)
      end

      def response_parser
        @response_parser ||= RentalsUnited::ResponseParser.new
      end

      def http
        @http_client ||= Concierge::HTTPClient.new(credentials.url)
      end

      def headers
        { "Content-Type" => "application/xml" }
      end

      def get_status(hash, root_tag_name)
        hash.get("#{root_tag_name}.Status")
      end

      def get_status_code(status)
        status.attributes["ID"]
      end

      def get_status_description(code)
        RentalsUnited::Dictionaries::Statuses.find(code)
      end

      def valid_status?(hash, root_tag_name)
        status = get_status(hash, root_tag_name)

        return false unless status

        VALID_RU_STATUS_CODES.include?(get_status_code(status))
      end

      def error_result(hash, root_tag_name)
        status = get_status(hash, root_tag_name)

        if status
          code = get_status_code(status)
          description = get_status_description(code)

          augment_with_error(code, description, caller)
          Result.error(code)
        else
          code = :unrecognised_response
          unrecognised_response_event(caller)
        end
        Result.error(code)
      end

      def augment_with_error(code, description, backtrace)
        message = "Response indicating the Status with ID `#{code}`, and description `#{description}`"
        mismatch(message, backtrace)
      end

      def mismatch(message, backtrace)
        response_mismatch = Concierge::Context::ResponseMismatch.new(
          message: message,
          backtrace: backtrace
        )

        Concierge.context.augment(response_mismatch)
      end

      def unrecognised_response_event(backtrace)
        message = "Error response could not be recognised (no `Status` tag in the response)"
        mismatch(message, backtrace)
      end
    end
  end
end
