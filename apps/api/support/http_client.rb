module API::Support

  # +API::Support::HTTPClient+
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
  #   client = API::Support::HTTPClient.new("https://api.roomorama.com")
  #   result = client.get("/users")
  #   if result.success?
  #     process_response(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  class HTTPClient

    # Bypass the default +Faraday+ connection. This is private and is not to be used
    # in production environments.
    class << self
      attr_accessor :_connection
    end

    CONNECTION_TIMEOUT = 10
    SUCCESSFUL_STATUSES = [200, 201]

    attr_reader :url, :username, :password

    # Creates a new +API::Support::HTTPClient+ instance.
    #
    # url        - the base URL to which upcoming requests will be performed.
    # basic_auth - a +Hash+ containing +username+ and +password+ for HTTP Basic Authentication
    def initialize(url, basic_auth = nil)
      @url = url

      if basic_auth
        @username = basic_auth.fetch(:username)
        @password = basic_auth.fetch(:password)
      end
    end

    def get(path, params = {})
      with_error_handling do |conn|
        conn.get(path, params)
      end
    end

    def post(path, params = {}, headers = {})
      with_error_handling do |conn|
        conn.headers.merge!(headers)
        conn.post(path, params)
      end
    end

    private

    def connection
      @connection ||= self.class._connection || Faraday.new(url: url, request: { timeout: CONNECTION_TIMEOUT }) do |f|
        f.adapter :patron

        if password
          f.adapter :basic_authentication, username, password
        end
      end
    end

    def with_error_handling
      response = yield(connection)

      if SUCCESSFUL_STATUSES.include?(response.status)
        Result.new(response)
      else
        Result.error(:"http_status_#{response.status}", response.body)
      end

    rescue Faraday::TimeoutError => err
      Result.error(:connection_timeout, err.message)
    rescue Faraday::ConnectionFailed => err
      Result.error(:connection_failed, err.message)
    rescue Faraday::SSLError => err
      Result.error(:ssl_error, err.message)
    rescue Faraday::Error => err
      Result.error(:network_failure, err.message)
    end

  end

end
