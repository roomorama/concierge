require_relative "version"

module Concierge

  # +Concierge::HTTPClient+
  #
  # This HTTP client is designed with error handling in mind. Networks are not
  # reliable, so code that performs any network related activity should be
  # prepared to handle failures gracefully.
  #
  # All requests performed through this class will have a default timeout of
  # 10 seconds. In addition to that, the return of every network related operation
  # from this class is an instance of the +Result+ object. This allows the caller
  # to determine if the call was successful and, in case it was not, handle
  # the error accordingly.
  #
  # Handled errors are:
  #
  #   * +:connection_timeout+ - happens if if takes more than 10 seconds to
  #                             get a response from the server.
  #   * +:connection_failed+  - when there is a problem connecting to the server.
  #   * +:ssl_error+          - when there was an SSL issue connecting to a server.
  #   * +:http_status_XXX+    - when the server returns a non-successful HTTP status (200, 201).
  #   * +:network_failure+    - general error category for any error network related failure.
  #
  # In all cases, the +Result+ object returned will have an error message associated
  # with the failure that can be logged somewhere for further analysis.
  #
  # Example
  #
  #   client = Concierge::HTTPClient.new("https://api.roomorama.com")
  #   result = client.get("/users")
  #   if result.success?
  #     process_response(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  class HTTPClient

    class << self
      # Bypass the default +Faraday+ connection. This is private and is not to be used
      # in production environments.
      attr_accessor :_connection
    end

    # events that are published via +Concierge::Announcer+ and that can be listened
    # independently.
    ON_REQUEST  = "http_client.on_request"
    ON_RESPONSE = "http_client.on_response"
    ON_FAILURE  = "http_client.on_failure"

    # by default, consider any request made through this HTTP client to be timed
    # out if no response is received within 10 seconds.
    CONNECTION_TIMEOUT = 10

    # if the HTTP response status is not 200, 201 or 202, then the request is
    # considered to have failed.
    SUCCESSFUL_STATUSES = [200, 201, 202]

    # by default, include a self identifying +User-Agent+ HTTP header so that
    # later analysis can pinpoint the running version of Concierge (and also
    # removes the default +Faraday+ User Agent configuration which is not
    # ideal.)
    DEFAULT_HEADERS = {
      "User-Agent" => "Roomorama/Concierge #{Concierge::VERSION}"
    }

    attr_reader :url, :username, :password

    # Creates a new +API::Support::HTTPClient+ instance.
    #
    # url     - the base URL to which upcoming requests will be performed.
    # options - a +Hash+ of options. Only +basic_auth+ is supported.
    #
    # Example
    #
    #   HTTPClient.new("https://www.example.org", basic_auth: {
    #     username: "user",
    #     password: "password"
    #   })
    def initialize(url, options = {})
      @url = url

      if options[:basic_auth]
        basic_auth = options.fetch(:basic_auth)
        connection.basic_auth(basic_auth.fetch(:username), basic_auth.fetch(:password))
      end
    end

    def get(path, params = {}, headers = {})
      with_error_handling do |conn|
        conn.headers.merge!(DEFAULT_HEADERS).merge!(headers)
        announce_request(:get, path, params, conn.headers)
        conn.get(path, params)
      end
    end

    def post(path, params = {}, headers = {})
      with_error_handling do |conn|
        conn.headers.merge!(DEFAULT_HEADERS).merge!(headers)
        announce_request(:post, path, params, conn.headers)
        conn.post(path, params)
      end
    end

    def put(path, params = {}, headers = {})
      with_error_handling do |conn|
        conn.headers.merge!(DEFAULT_HEADERS).merge!(headers)
        conn.put(path, params)
      end
    end

    def delete(path, params = {}, headers = {})
      with_error_handling do |conn|
        conn.headers.merge!(DEFAULT_HEADERS).merge!(headers)
        conn.delete(path, params)
      end
    end

    private

    def connection
      @connection ||= self.class._connection || Faraday.new(url: url, request: { timeout: CONNECTION_TIMEOUT }) do |f|
        f.adapter :patron
      end
    end

    def with_error_handling
      response   = yield(connection)
      successful = true
      announce_response(response)

      if SUCCESSFUL_STATUSES.include?(response.status)
        Result.new(response)
      else
        Result.error(:"http_status_#{response.status}")
      end

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

    def announce_request(method, path, params, headers)
      # if this is a GET request, +params+ is interpreted to be a query string,
      # and is properly represented as such below. For other HTTP methods,
      # the given parameters are sent in the request body.
      if method == :get
        query_string = URI.encode_www_form(params)
      else
        body = params
      end

      full_url = [url, path].join
      Concierge::Announcer.trigger(ON_REQUEST, method, full_url, query_string, headers, body)
    end

    def announce_response(response)
      Concierge::Announcer.trigger(ON_RESPONSE, response.status, response.headers, response.body)
    end

    def announce_error(error)
      Concierge::Announcer.trigger(ON_FAILURE, error.message)
    end

    def run_on_error_hook(error)
      return unless hooks.on_error
      hooks.on_error.call(error.message)
    end

  end

end
