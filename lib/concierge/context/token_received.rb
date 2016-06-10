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
  #   request = Concierge::Context::TokenReceived.new( token_hash:{
  #     "token_type"=>"BEARER",
  #     "access_token"=>"test_token",
  #     "expires_at"=>1465467451
  #   } )
  #
  # All named parameters on initialization are required. This class conforms to
  # the expected protocol of Concierge events, responding to the +to_h+ method,
  # producing a serialized version of the data given.
  class TokenReceived

    # This is the content of events of the +type+ field of the event
    # registering network requests.
    CONTEXT_TYPE = "token_request"

    attr_reader :token_hash, :timestamp

    def initialize(token_hash:)
      @token_hash = truncate_token(token_hash)
      @timestamp  = Time.now
    end

    def to_h
      {
        type:       CONTEXT_TYPE,
        timestamp:  timestamp,
        token_hash: token_hash
      }
    end

    # Truncates the token field in the hash
    def truncate_token token_hash
      hash = token_hash.dup
      hash[:access_token] = hash[:access_token][0..3] + "..."
      hash
    end

  end

end
