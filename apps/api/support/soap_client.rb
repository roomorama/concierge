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
  # This SOAP client uses +Concierge::Announcer+ to publish events related to SOAP
  # requests. Events available are:
  #
  # * +ON_REQUEST+ - triggered before a request to the server is performed. Parameters are:
  #   - +endpoint+  - the endpoint to be called
  #   - +operation+ - the SOAP operation
  #   - +message+   - the message being sent (XML payload)
  #
  # * +ON_RESPONSE+ - triggered after a response is received back from the SOAP servers. Parameters:
  #   - +code+    - the underlying HTTP response code of the response
  #   - +headers+ - the underlying HTTP headers coming from the server
  #   - +body+    - the response body.
  #
  # * +ON_FAILURE+ - triggered when there is a failure (network related, remote server issue
  #                  a generic SOAP fault.) Parameters:
  #   - +message+ - a message describing the failure
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

    # events published via +Concierge::Announcer+ so that any listener can subscribe
    # and process the information if necessary
    ON_REQUEST  = "soap_client.on_request"
    ON_RESPONSE = "soap_client.on_response"
    ON_FAILURE  = "soap_client.on_failure"

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def call(operation, locals = {})
      with_error_handling do |cli|
        announce_request(operation, locals)
        cli.call(operation, locals)
      end
    end

    def client
      Savon.client(options)
    end

    private

    def with_error_handling
      response = yield(client)
      announce_response(response)

      Result.new(response.body)

    rescue Savon::HTTPError => err
      announce_error(err.message)
      Result.error("http_status_#{err.http.code}", err.message)
    rescue Savon::InvalidResponseError => err
      announce_error(err.message)
      Result.error(:invalid_response, err.message)
    rescue Savon::UnknownOperationError => err
      announce_error(err.message)
      Result.error(:unknown_operation, err.message)
    rescue Savon::SOAPFault => err
      announce_error(err.message)
      Result.error(:soap_error, err.message)
    rescue Savon::Error => err
      announce_error(err.message)
      Result.error(:savon_error, err.message)
    end

    def announce_request(operation, locals)
      Concierge::Announcer.trigger(ON_REQUEST,
        options[:endpoint],
        operation,
        locals[:message]
      )
    end

    def announce_response(response)
      http = response.http

      Concierge::Announcer.trigger(ON_RESPONSE,
        http.code,
        http.headers,
        http.body
      )
    end

    def announce_error(message)
      Concierge::Announcer.trigger(ON_FAILURE, message)
    end

  end
end
