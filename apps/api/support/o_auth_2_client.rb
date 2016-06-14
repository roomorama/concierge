require 'oauth2'

module API::Support

  # +API::Support::OAuth2Client+
  #
  # This class wraps OAuth2 client functionalities(from gem oauth2)
  # with error handling(by +Result+ class)
  #
  # Strategy defaults to OAuth2 by client credentials. @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.4
  #
  # The return of every network related operation from this class is an instance of the +Result+ object.
  # This allows the caller to determine if the call was successful and, in case it was not,
  # handle the error accordingly.
  #
  # Usage
  #
  #   client = API::Support::OAuth2Client.new(id: "id",
  #                                           secret: "secret",
  #                                           base_url: "https://url",
  #                                           token_url: "/oauth/token",
  #                                           authorize_url: "/oauth/authorize" # only for :authorize strategy
  #                                           strategy: :client_credentials)
  #   result = client.get(endpoint)
  #   if result.success?
  #     process_response(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  class OAuth2Client

    attr_reader :options, :oauth_client

    def initialize(id:, secret:, base_url:, token_url:, **options)
      @options = options
      oauth_options = {
        token_url: token_url,
        site: base_url
      }.merge options
      @oauth_client = OAuth2::Client.new(id,
                                  secret,
                                  **oauth_options)
    end


    # Make a GET request with the client's access_token
    #
    def get(path, opts = {}, &block)
      response_with_error_handling do
        access_token.get(path, opts, &block)
      end
    end

    # Make a POST request with the client's access_token
    #
    def post(path, opts = {}, &block)
      response_with_error_handling do
        access_token.post(path, opts, &block)
      end
    end

    private

    # Fetch the access token from cache by id.
    # TODO: - Expire the cache according to the returned token's expire_at.
    #         Currently we request for a new token every 1 day, arbitrarily
    #
    def access_token
      return @access_token unless @access_token.nil?

      token_result = cache.fetch(oauth_client.id, freshness: one_day, serializer: json_serializer ) do
        token_strategy = options.fetch(:strategy, :client_credentials)
        @access_token = oauth_client.public_send(token_strategy).get_token
        Result.new(@access_token.to_hash)
      end

      # If cache is hit, we need to parse result into an +OAuth2::AccessToken+ object
      @access_token = OAuth2::AccessToken.from_hash(oauth_client, token_result.value) unless token_result.nil?
    end

    def response_with_error_handling
      response = yield
      json_serializer.decode(response.body)
    rescue OAuth2::Error => err
      announce_error(err)
      Result.error(:"http_status_#{err.response.status}", err.response.body)
    rescue Faraday::TimeoutError => err
      announce_error(err)
      Result.error(:connection_timeout)
    rescue Faraday::ConnectionFailed => err
      announce_error(err)
      Result.error(:connection_failed)
    rescue Faraday::SSLError => err
      announce_error(err)
      Result.error(:ssl_error)
    rescue Faraday::Error => err
      announce_error(err)
      Result.error(:network_failure)
    end

    def announce_error(error)
      Concierge::Announcer.trigger("oauth2_client.on_failure", error.message)
    end

    def cache
      @cache ||= Concierge::Cache.new(namespace: "oauth2")
    end

    def one_day
      60 * 60 * 24
    end

    def json_serializer
      @serializer ||= Concierge::Cache::Serializers::JSON.new
    end
  end
end

