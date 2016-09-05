module Woori
  module Commands
    class BaseFetcher
      attr_reader :credentials

      DEFAULT_LOCALE = "en-US"

      def initialize(credentials)
        @credentials = credentials
      end

      def http
        @http_client ||= Concierge::HTTPClient.new(credentials.url)
      end
    
      def headers
        {
          "Content-Type" => "application/json",
          "Authorization" => credentials.api_key
        }
      end
    end
  end
end
