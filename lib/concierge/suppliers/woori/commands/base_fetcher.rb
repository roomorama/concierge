module Woori
  module Commands
    class BaseFetcher
      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def endpoint(name)
        Woori::Endpoint.endpoint_for(name)
      end

      def response_parser
        @response_parser ||= Woori::ResponseParser.new
      end

      def http
        @http_client ||= Concierge::HTTPClient.new(credentials.url, timeout: 20)
      end
    
      def headers
        {
          "Content-Type" => "application/json",
          "Authorization" => credentials.api_key
        }
      end
    
      def valid_result?(hash)
        true
      end

      def error_result(hash)
      end
    end
  end
end
