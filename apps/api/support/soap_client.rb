module API::Support

  # +API::Support::SOAPClient+
  #
  # This SOAP client is designed with error handling.
  #
  # The return of every network related operation from this class is an instance of the +Result+ object.
  # This allows the caller to determine if the call was successful and, in case it was not,
  # handle the error accordingly.
  #
  # Handled errors are:
  #
  #   * +:http_status_XXX+    - when the server returns a non-successful HTTP status (4XX, 5XX).
  #   * +:soap_fault+         - happens if sent invalid request
  #   * +:invalid_response+   - when got invalid resonse from the server.
  #   * +:unknown_operation+  - when call unknown operation.
  #   * +:savon_error+        - generic savon error.
  #
  # In all cases, the +Result+ object returned will have an error message associated
  # with the failure that can be logged somewhere for further analysis.
  #
  # Example
  #
  #   client = API::Support::SOAPClient.new(wsdl: "https://example.com?wsdl")
  #   result = client.call(:operation_name, message: { *some data here* })
  #   if result.success?
  #     process_response(result.value)
  #   else
  #     handle_error(result.error)
  #   end

  class SOAPClient

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def call(*args)
      with_error_handling do |cli|
        cli.call(*args)
      end
    end

    def client
      Savon.client(options)
    end

    private

    def with_error_handling
      response = yield(client)

      Result.new(response.body)

    rescue Savon::HTTPError => err
      Result.error("http_status_#{err.http.code}", err.message)
    rescue Savon::InvalidResponseError => err
      Result.error(:invalid_response, err.message)
    rescue Savon::UnknownOperationError => err
      Result.error(:unknown_operation, err.message)
    rescue Savon::SOAPFault => err
      Result.error(:soap_error, err.message)
    rescue Savon::Error => err
      Result.error(:savon_error, err.message)
    end

  end
end