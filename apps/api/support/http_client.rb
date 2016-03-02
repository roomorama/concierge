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

    CONNECTION_TIMEOUT = 10

    attr_reader :url

    # Creates a new +API::Support::HTTPClient+ instance.
    #
    # url - the base URL to which upcoming requests will be performed.
    def initialize(url)
      @url = url
    end

    def get(path, params = {})
      with_error_handling do |conn|
        conn.get(path, params)
      end
    end

    def post(path, params = {})
      with_error_handling do |conn|
        conn.post(path, params)
      end
    end

    private

    def connection
      @connection ||= Faraday.new(url: url, request: { timeout: CONNECTION_TIMEOUT }) do |f|
        f.adapter :patron
      end
    end

    def with_error_handling
      result = Result.new(yield connection)

    rescue Faraday::TimeoutError => err
      error(:connection_timeout, err.message)
    rescue Faraday::ConnectionFailed => err
      error(:connection_failed, err.message)
    rescue Faraday::SSLError => err
      error(:ssl_error, err.message)
    rescue Faraday::Error => err
      error(:network_failure, err.message)
    end

    def error(code, message)
      Result.new.tap do |r|
        r.error.code    = code
        r.error.message = message
      end
    end

  end

end
