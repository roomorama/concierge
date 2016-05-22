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
  # The client is also enables the caller to associate hooks to diferent moments
  # of the request cycle:
  #
  # +on_request+  - called before an HTTP request is performed
  # +on_response+ - called when an HTTP response is received.
  # +on_error+    - called when there is an error while making a request,
  #                 which could not be finished.
  #
  # Example
  #
  #   Concierge::HTTPClient.on_request do |http_method, url, query, headers, body|
  #     log_request(http_method, headers)
  #   end
  #
  #   client = Concierge::HTTPClient.new("https://api.roomorama.com")
  #   result = client.get("/users") # => +log_request+ is called
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

      # container structure to hold the three possible hooks that can be associated
      # with the HTTP client when performing network requests.
      Hooks = Struct.new(:on_request, :on_response, :on_error)

      # associates the given block to an +on_request+event. The block given
      # is invoked whenever an HTTP request is about to be performed.
      #
      # The block receives the following parameters:
      #
      # * +method+       - the HTTP method of the request being performed.
      # * +url+          - the URL of the request being performed.
      # * +query_string+ - the query string, if any
      # * +headers+      - the HTTP headers being sent.
      # * +body+         - the request body, if any.
      def on_request(&block)
        hooks.on_request = block
      end

      # associates the given block to an +on_response+ event. The block given
      # is invoked whenever an HTTP response is received from a server.
      #
      # The block receives the following parameters:
      #
      # * +status+  - the HTTP status of the response
      # * +headers+ - the HTTP response headers
      # * +body+    - the response body, if any
      def on_response(&block)
        hooks.on_response = block
      end

      # associates the given block to an +on_error+ event. The block given
      # is invoked whenever there is an error performing an HTTP call and
      # the request is not finished (no response is received back.)
      #
      # The block receives the following parameters:
      #
      # * +message+ - the message associated with the error.
      def on_error(&block)
        hooks.on_error = block
      end

      private

      def hooks
        @hooks ||= Hooks.new
      end
    end

    CONNECTION_TIMEOUT = 10
    SUCCESSFUL_STATUSES = [200, 201]

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
        conn.headers.merge!(headers)
        run_on_request_hook(:get, params, conn.headers)
        conn.get(path, params)
      end
    end

    def post(path, params = {}, headers = {})
      with_error_handling do |conn|
        conn.headers.merge!(headers)
        run_on_request_hook(:post, params, conn.headers)
        conn.post(path, params)
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
      run_on_response_hook(response)

      if SUCCESSFUL_STATUSES.include?(response.status)
        Result.new(response)
      else
        Result.error(:"http_status_#{response.status}", response.body)
      end

    rescue Faraday::TimeoutError => err
      run_on_error_hook(err)
      Result.error(:connection_timeout, err.message)
    rescue Faraday::ConnectionFailed => err
      run_on_error_hook(err)
      Result.error(:connection_failed, err.message)
    rescue Faraday::SSLError => err
      run_on_error_hook(err)
      Result.error(:ssl_error, err.message)
    rescue Faraday::Error => err
      run_on_error_hook(err)
      Result.error(:network_failure, err.message)
    end

    def run_on_request_hook(method, params, headers)
      return unless hooks.on_request

      # if this is a GET request, +params+ is interpreted to be a query string,
      # and is properly represented as such below. For other HTTP methods,
      # the given parameters are sent in the request body.
      if method == :get
        query_string = URI.encode_www_form(params)
      else
        body = params
      end

      hooks.on_request.call(method, url, query_string, headers, body)
    end

    def run_on_response_hook(response)
      return unless hooks.on_response
      hooks.on_response.call(response.status, response.headers, response.body)
    end

    def run_on_error_hook(error)
      return unless hooks.on_error
      hooks.on_error.call(error.message)
    end

    def hooks
      @hooks ||= self.class.send(:hooks)
    end

  end

end
