module Woori
  # +Woori::Importer+
  #
  # This class provides an interface for the bulk import of Woori properties.
  #
  # Usage
  #
  #   importer = Woori::Importer.new(credentials)
  #   importer.fetch_properties
  #
  #   => RESULT - TODO
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def fetch_properties
      client_for(endpoint).invoke(endpoint)
    end

    private

    def client_for
      Concierge::HTTPClient.new(credentials, api_token)
    end

    def api_token
      # basic_auth: { "Authorization": "API_KEY_123" }
    end

    def endpoint
      # Build from Woori::Request class
    end

  end
end