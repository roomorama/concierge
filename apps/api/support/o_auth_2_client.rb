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
  #   result = client.get(endpoint)
  #   if result.success?
  #     process_response(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  class OAuth2Client
    include Concierge::JSON

    attr_reader :options, :cache, :oauth_client

    def initialize(options={})
      @options = options
    end

    # Fetch the access token from cache by id.
    # TODO: - Expire the cache according to the returned token's expire_at.
    #         Currently we request for a new token every 1 day, arbitrarily
    #
    def access_token
      return @access_token unless @access_token.nil?

      token_result = cache.fetch(options.fetch(:id), freshness: 60 * 60 * 24 ) do
        @access_token = oauth_client.client_credentials.get_token
        Result.new(@access_token.to_hash.to_json)
      end

      # If cache is hit, we need to parse result into an +OAuth2::AccessToken+ object
      @access_token = OAuth2::AccessToken.from_hash(oauth_client, JSON.parse(token_result.value)) unless token_result.nil?
    rescue OAuth2::Error => err

    end

    # Make a GET request with the client's access_token
    #
    def get(path, opts = {}, &block)
      with_error_handling do
        access_token.get(path, opts, &block)
      end
    end

    # Make a POST request with the client's access_token
    #
    def post(path, opts = {}, &block)
      with_error_handling do
        access_token.post(path, opts, &block)
      end
    end

    def oauth_client
      @oauth_client ||= OAuth2::Client.new(options.fetch(:id),
                                  options.fetch(:secret),
                                  token_url: options.fetch(:token_url, "/oauth/token"),
                                  site: options.fetch(:base_url))
    end

    private

    def with_error_handling
      response = yield
      if Concierge::HTTPClient::SUCCESSFUL_STATUSES.include?(response.status)
        Result.new(json_decode(response.body))
      else
        announce_error(response.error)
        Result.error(:"http_status_#{respoesn.status}")
      end
    rescue OAuth2::Error => err
      announce_error(err)
      Result.error(err.code)
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


    def cache
      @cache ||= Concierge::Cache.new(namespace: "oauth2")
    end
  end
end

