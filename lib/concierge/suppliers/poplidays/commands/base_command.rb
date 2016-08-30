module Poplidays
  module Commands
    # +Poplidays::Commands::BaseCommand+
    #
    # Base class for all call Poplidays API commands. Each child should
    # implement two methods:
    #  - method - HTTP method to be used for remote call
    #  - path - the part of URL after domain and API's version. It can
    #           contains named parameters to be placed using sprintf function
    #           Example: 'lodgings/%<id>s/availabilities'
    #  - authentication_required? - if command requires authentication
    class BaseCommand
      include Concierge::JSON

      # Poplidays API version
      VERSION = 'v2'
      # URL for API calls. All calls are relative to this endpoint.
      URL = 'api.poplidays.com'
      DEFAULT_PROTOCOL = 'https'

      CACHE_PREFIX = 'poplidays'

      # Poplidays support XML and JSON responses, the former being the default.
      # Therefore, every API call need to explicitly indicate that a JSON
      # response is preferred.
      HEADERS  = { 'Accept'          => 'application/json',
                   'Accept-Language' => 'en'}

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      protected

      # Executes remote call with given params
      #
      # Arguments
      #
      #   * +url_params+ [Hash] a hash of params to be inserted to the command path
      #                         with sprintf method
      #   * +params+ [Hash] HTTP params (POST or GET) to be sent during remote call
      def remote_call(url_params = {}, params = {})
        endpoint = sprintf("#{VERSION}/#{path}", url_params)

        auth_params = {}
        if authentication_required?
          auth_params = { client: credentials.client_key, signature: sign_request(endpoint) }
        end

        if method == :get
          params.merge!(auth_params)
          response = client.get(endpoint, params, HEADERS)
        elsif method == :post
          endpoint += escape_params(auth_params)
          response = client.post(endpoint, params, HEADERS)
        end

        if response.success?
          Result.new(response.value.body)
        else
          response
        end
      end

      def with_cache(key, freshness: Concierge::Cache::DEFAULT_TTL)
        cache.fetch(key, freshness: freshness) { yield }
      end

      def cache
        @cache ||= Concierge::Cache.new(namespace: CACHE_PREFIX)
      end

      def protocol
        DEFAULT_PROTOCOL
      end

      def method
        raise NotImplementedError
      end

      def path
        raise NotImplementedError
      end

      def authentication_required?
        raise NotImplementedError
      end

      private

      def client
        url = "#{protocol}://#{URL}"
        @client ||= Concierge::HTTPClient.new(url, options = {timeout: 180})
      end

      def escape_params(params)
        URI.escape(params.collect{|k,v| "#{k}=#{v}"}.join('&'))
      end

      def sign_request(endpoint)
        passphrase = credentials.passphrase
        client_key = credentials.client_key
        mixed = "#{passphrase}:#{endpoint}:client:#{client_key}"
        Digest::SHA1.hexdigest(mixed)
      end
    end
  end
end