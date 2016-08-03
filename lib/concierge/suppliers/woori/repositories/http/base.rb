module Woori::Repositories::HTTP
  class Base
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def response_parser
      @response_parser ||= Woori::ResponseParser.new
    end

    def http
      @http_client ||= Concierge::HTTPClient.new(credentials.url, timeout: 30)
    end
  
    def headers
      {
        "Content-Type" => "application/json",
        "Authorization" => credentials.api_key
      }
    end

    def default_locale
      "en-US"
    end
  end
end
