module Poplidays
  module Commands
    # +Poplidays::Commands::BaseCommand+
    #
    # Base class for all call Poplidays API commands. Each child should
    # implement three methods:
    #  - method - HTTP method to be used for remote call
    #  - path - the part of URL after domain and API's version. It can
    #           contains named parameters to be placed using sprintf function
    #           Example: 'lodgings/%<id>s/availabilities'
    #  - authentication - returns BaseCommand::Authentication or BaseCommand::NullAuthentication,
    #                     BaseCommand#with_authentication and BaseCommand#without_authentication can
    #                     be used to create appropriate object
    class BaseCommand
      include Concierge::JSON


      # Poplidays API version
      VERSION = 'v2'
      DEFAULT_PROTOCOL = 'https'

      CACHE_PREFIX = 'poplidays'

      # Http timeout in seconds
      DEFAULT_TIMEOUT = 10

      # Poplidays support XML and JSON responses, the former being the default.
      # Therefore, every API call need to explicitly indicate that a JSON
      # response is preferred.
      HEADERS  = { 'Accept'          => 'application/json',
                   'Accept-Language' => 'en'}

      ROOMORAMA_DATE_FORMAT = '%Y-%m-%d'
      POPLIDAYS_DATE_FORMAT = '%Y%m%d'

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
      def remote_call(url_params: {})
        endpoint = sprintf("#{VERSION}/#{path}", url_params)

        endpoint += authentication.to_query(endpoint)
        if method == :get
          response = client.get(endpoint, {}, HEADERS)
        elsif method == :post
          response = client.post(endpoint, json_encode(params), {'Content-Type' => 'application/json'}.merge!(HEADERS))
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

      def authentication
        raise NotImplementedError
      end


      def timeout
        DEFAULT_TIMEOUT
      end

      # Converts date string to Poplidays expected format
      def convert_date(date)
        Date.strptime(date, ROOMORAMA_DATE_FORMAT).strftime(POPLIDAYS_DATE_FORMAT)
      end

      def with_authentication
        Authentication.new(credentials)
      end

      def without_authentication
        NullAuthentication.new
      end

      private

      def client
        url = "#{protocol}://#{credentials.url}"
        @client ||= Concierge::HTTPClient.new(url, timeout: timeout)
      end

      class Authentication
        attr_reader :credentials

        def initialize(credentials)
          @credentials = credentials
        end

        def sign(path)
          { client: credentials.client_key, signature: sign_request(path) }
        end

        def to_query(path)
          ['?', URI.encode_www_form(sign(path))].join
        end

        private

        def sign_request(path)
          passphrase = credentials.passphrase
          client_key = credentials.client_key
          mixed = "#{passphrase}:/#{path}:client:#{client_key}"
          Digest::SHA1.hexdigest(mixed)
        end
      end

      class NullAuthentication
        def sign(path)
          {}
        end

        def to_query(path)
          ''
        end
      end
    end
  end
end