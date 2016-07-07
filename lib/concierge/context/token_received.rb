class Concierge::Context

  # +Concierge::Context::TokenReceived+
  #
  # This class represents the event of an oauth2 token request
  # being performed by +Concierge::OAuth2Client. This warrants
  # its own class of context because an oauth2 token request can
  # be of many different strategies, each having its own request
  # body and headers.
  #
  # Usage
  #
  #   request = Concierge::Context::TokenReceived.new(
  #     access_token: "test_token",
  #     expires_at: 1465467451
  #     params: {"token_type"=>"BEARER", "scope"=>"basic"}
  #   )
  #
  # All named parameters on initialization are required. This class conforms to
  # the expected protocol of Concierge events, responding to the +to_h+ method,
  # producing a serialized version of the data given.
  class TokenReceived

    # This is the content of events of the +type+ field of the event
    # registering network requests.
    CONTEXT_TYPE = "token_received"

    attr_reader :params, :access_token, :expires_at, :timestamp

    def initialize(access_token:, expires_at:, params:)
      @access_token = truncate(access_token)
      @expires_at = Time.at expires_at
      @params = params
      @timestamp  = Time.now
    end

    def to_h
      {
        type:         CONTEXT_TYPE,
        timestamp:    timestamp,
        access_token: access_token,
        expires_at:   expires_at,
        params:       params,
      }
    end

    private

    def truncate(secret)
      secret[0..3] + "..."
    end

  end

end
