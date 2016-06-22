module SAW
  module Commands
    class BaseFetcher
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
        @http_client ||= Concierge::HTTPClient.new(credentials.url)
      end
    
      def content_type
        { "Content-Type" => "application/xml" }
      end
    
      def valid_result?(hash)
        hash.get("response.errors").nil?
      end

      def error_result(hash)
        error = hash.get("response.errors.error")
        code = error.get("code")
        data = error.get("description")

        Result.error(code, data)
      end
    end
  end
end
