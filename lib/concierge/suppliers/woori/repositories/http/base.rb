module Woori::Repositories::HTTP
  # +Woori::Repositories::HTTP::Base+
  #
  # Class is responsible for providing basic methods needed for all inhereted
  # classes: http client, default headers and api locale.
  class Base
    include Concierge::JSON

    attr_reader :credentials

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

    def default_locale
      "en-US"
    end
  end
end
