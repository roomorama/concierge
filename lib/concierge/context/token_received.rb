class Concierge::Context

  # +Concierge::Context::TokenReceived+
  #
  # This class represents the event of an oauth2 token request
  # being performed by +API::Support::OAuth2Client. This warrants
  # its own class of context because an oauth2 token request can
  # be of many different strategies, each having its own request
  # body and headers.
  #
  # Usage
  #
  #   request = Concierge::Context::TokenReceived.new(
  #     token_type: "BEARER",
  #     access_token: "test_token",
  #     expires_at: 1465467451
  #   )
  #
  # All named parameters on initialization are required. This class conforms to
  # the expected protocol of Concierge events, responding to the +to_h+ method,
  # producing a serialized version of the data given.
  class TokenReceived

    # This is the content of events of the +type+ field of the event
    # registering network requests.
    CONTEXT_TYPE = "token_received"

    attr_reader :token_type, :access_token, :expires_at, :timestamp

    def initialize(token_type:, access_token:, expires_at:)
      @token_type = token_type
      @access_token = truncate(access_token)
      @expires_at = expires_at
      @timestamp  = Time.now
    end

    def to_h
      {
        type:         CONTEXT_TYPE,
        timestamp:    timestamp,
        token_type:   token_type,
        access_token: access_token,
        expires_at:   expires_at
      }
    end

    private

    def truncate(secret)
      secret[0..3] + "..."
    end

  end

end
