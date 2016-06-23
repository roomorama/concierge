module SAW
  # +SAW::Price+
  #
  # This class is responsible for wrapping the logic related to making a price
  # quotation to SAW, parsing the response, and building the +Quotation+ object
  # with the data returned from their API.
  #
  # Usage
  #
  #   result = SAW::Price.new(credentials).quote(stay_params)
  #   if result.success?
  #     process_quotation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The +quote+ method returns a +Result+ object that, when successful, encapsulates the
  # resulting +Quotation+ object.
  class Price
    attr_reader :credentials, :payload_builder, :response_parser

    def initialize(credentials, payload_builder: nil, response_parser: nil)
      @credentials = credentials
      @payload_builder = payload_builder || default_payload_builder
      @response_parser = response_parser || default_response_parser
    end

    # Calls the SAW API method using the HTTP client.
    # Returns a +Result+ object.
    def quote(params)
      payload = payload_builder.build_compute_pricing(params)
      result = http.post(endpoint_for(:property_rates), payload, content_type)

      if result.success?
        result_hash = response_parser.to_hash(result.value.body)

        if valid_result?(result_hash)
          property_rate = SAW::Mappers::PropertyRate.build(result_hash)
          quotation = SAW::Mappers::Quotation.build(params, property_rate)
        
          Result.new(quotation)
        else
          error_result(result_hash)
        end
      else
        result
      end
    end

    private
    def default_payload_builder
      @payload_builder ||= SAW::PayloadBuilder.new(credentials)
    end

    def default_response_parser
      @response_parser ||= SAW::ResponseParser.new
    end

    def http
      @http_client ||= Concierge::HTTPClient.new(credentials.url)
    end

    def endpoint_for(method)
      SAW::Endpoint.endpoint_for(method)
    end

    def content_type
      { "Content-Type" => "application/xml" }
    end

    def valid_result?(hash)
      if hash.get("response")
        hash.get("response.errors").nil?
      else
        false
      end
    end

    def error_result(hash)
      if hash.get("response.errors")
        code = hash.get("response.errors.error.code")
        data = hash.get("response.errors.error.description")
        
        Result.error(code, data)
      else
        Result.error(:unrecognised_response)
      end
    end
  end
end
