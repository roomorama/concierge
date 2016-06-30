class Concierge::Context

  # +Concierge::Context::TokenRequest+
  #
  # This class represents the event of an oauth2 token request
  # being performed by +Concierge::OAuth2Client. This warrants
  # its own class of context because an oauth2 token request can
  # be of many different strategies, each having its own request
  # body and headers.
  #
  # Usage
  #
  #   request = Concierge::Context::TokenRequest.new(
  #     site: site,
  #     id: id,
  #     secret: secret,
  #     strategy: strategy
  #   )
  #
  # All named parameters on initialization are required. This class conforms to
  # the expected protocol of Concierge events, responding to the +to_h+ method,
  # producing a serialized version of the data given.
  class TokenRequest

    # This is the content of events of the +type+ field of the event
    # registering network requests.
    CONTEXT_TYPE = "token_request"

    attr_reader :site, :client_id, :client_secret, :strategy, :timestamp

    def initialize(site:, client_id:, client_secret:, strategy:)
      @site = site
      @client_id = truncate(client_id)
      @client_secret = truncate(client_secret)
      @strategy = strategy
      @timestamp   = Time.now
    end

    def to_h
      {
        type:          CONTEXT_TYPE,
        timestamp:     timestamp,
        site:          site,
        client_id:     client_id,
        client_secret: client_secret,
        strategy:      strategy
      }
    end

    private

    def truncate(secret)
      secret[0..3] + "..."
    end

  end

end
