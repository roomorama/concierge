module API::Support

  # +API::Support::JSONRPC
  #
  # This class is a client for the JSON-RPC 2.0 protocol.
  # Specification: http://www.jsonrpc.org/specification.
  #
  # Usage
  #
  #   endpoint = "https://jsonrpc-server.example.org"
  #   client = API::Support::JSONRPC.new(endpoint)
  #
  #   result = client.invoke("method", { arg1: "arg", arg2: "arg2" })
  #   if result.success?
  #     process_response(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # See the protocol specification in the link above for a better understanding
  # of how the protocol works.
  #
  # Possible errors from the method invokation are:
  #
  # * +json_rpc_invalid_json_response+:     the response given by the server is not a valid JSON.
  # * +json_rpc_response_ids_do_not_match+: happens when the response returned by the server
  #                                         has an ID different from the one provided in the request.
  # * +json_rpc_response_has_errors+:       the response returned by the server reports errors.
  # * +invalid_json_rpc_response+:          if the JSON returned by the server does not conform
  #                                         to the JSON-RPC 2.0 protocol.
  #
  # In all the error scenarios, an error message is provided for more information
  # and further analysis.
  #
  # Note that if there is a network-related issue and the request cannot be performed,
  # the error from +API::Support::HTTPClient+ will be forwarded to the caller.
  class JSONRPC

    PROTOCOL_VERSION = "2.0"

    attr_reader :url, :endpoint, :path

    def initialize(url)
      @url = url

      uri = URI(url)
      @endpoint = [uri.scheme, "://", uri.host].join
      @path = uri.path
    end

    # actually performs the HTTP request to the JSON-RPC server requesting the
    # given +method+ to be performed with the given parameters, if any.
    #
    # This returns a +Result+ object. Check for its status to determine if the
    # call was successful or what error happened during the process
    def invoke(method, params = {})
      payload = jsonrpc_payload(method, params)
      result = http.post(path, payload, { "Content-Type" => "application/json" })

      if result.success?
        parse_response(result.value, request_id: payload.fetch(:id))
      else
        result
      end
    end

    private

    # Parses a JSON-RPC response. See class documentation for possible errors that
    # can be found in this process.
    #
    # A valid response must include:
    #
    # * an +id+ that matches the request ID.
    # * No +error+ element in the response.
    # * A +data+ element in the response.
    def parse_response(response, request_id:)
      parsed_data = to_json(response.body)
      return parsed_data unless parsed_data.success?

      json_response = parsed_data.value
      if json_response["id"] != request_id
        return wrong_response_id(request_id, json_response["id"])
      end

      if json_response.has_key?("error")
        code    = json_response["error"]["code"]
        message = json_response["error"]["message"]

        return Result.error(:json_rpc_response_has_errors, [code, message].join(" - "))
      end

      if json_response.has_key?("result")
        Result.new(json_response["result"])
      else
        Result.error(:invalid_json_rpc_response, json_response.to_s)
      end
    end

    def wrong_response_id(expected, actual)
      Result.error(:json_rpc_response_ids_do_not_match, "Expected: #{expected}, Actual: #{actual}")
    end

    def to_json(data)
      Result.new(parser.parse(data))
    rescue Yajl::ParseError => err
      Result.error(:invalid_json_response, err.message)
    end

    def parser
      @parser ||= Yajl::Parser.new
    end

    def http
      @http_client ||= HTTPClient.new(endpoint)
    end

    def jsonrpc_payload(method, params)
      payload = {
        jsonrpc: PROTOCOL_VERSION,
        id:      request_id,
        method:  method
      }

      unless params.empty?
        payload.merge!(params: params)
      end

      payload
    end

    # generates a 12-digits long random number
    def request_id
      rand(10 ** 12)
    end

  end

end
