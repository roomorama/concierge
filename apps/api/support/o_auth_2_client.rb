require 'oauth2'

module API::Support

  # +API::Support::OAuth2Client+
  #
  # This class wraps OAuth2 client functionalities(from gem oauth2)
  # with error handling(by +Result+ class)
  #
  # The return of every network related operation from this class is an instance of the +Result+ object.
  # This allows the caller to determine if the call was successful and, in case it was not,
  # handle the error accordingly.
  #
  # Usage
  #
  #   client = API::Support::OAuth2Client.new(id: "id",
  #                                           secret: "secret",
  #                                           base_url: "https://url")
  #   result = client.invoke(endpoint)
  #   if result.success?
  #     process_response(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  class OAuth2Client

    attr_reader :options, :cache, :oauth_client

    def initialize(options={})
      @options = options
      @oauth_client = OAuth2::Client.new(options.fetch(:id),
                                  options.fetch(:secret),
                                  token_url: options.fetch(:token_url, "/oauth/token"),
                                  site: options.fetch(:base_url))
      @cache = Concierge::Cache.new(namespace: "oauth2")
    end

    # Fetch the access token from cache by id.
    # TODO: - Expire the cache according to the returned token's expire_at.
    #         Currently we request for a new token every 1 day, arbitrarily
    def access_token
      token_result = cache.fetch(options.fetch(:id), freshness: 60 * 60 * 24 ) do
        @access_token = oauth_client.client_credentials.get_token
        Result.new(@access_token.to_hash.to_json)
      end

      # If cache is hit, we need to parse result into an +OAuth2::AccessToken+ object
      @access_token = OAuth2::AccessToken.from_hash(oauth_client, JSON.parse(token_result.value)) unless token_result.nil?
    end

  end
end

