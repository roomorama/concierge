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
        if hash.get("response")
          hash.get("response.errors").nil?
        else
          false
        end
      end

      def error_result(hash)
        if hash.get("response.errors")
          code = hash.get("response.errors.error.code")
          data = hash.get("response.errors.error.description")
          
          Result.error(code, data)
        else
          Result.error(:unrecognised_response)
        end
      end
    end
  end
end
