module Support
  module Woori
    module MockRequest
      def mock_request(endpoint, filename, status: 200)
        stub_data = read_fixture("woori/#{endpoint}/#{filename}.json")
        stub_call(:get, endpoint_for(endpoint)) { [status, {}, stub_data] }
      end

      def mock_bad_json_request(endpoint)
        stub_data = read_fixture("woori/bad_response.json")
        stub_call(:get, endpoint_for(endpoint)) { [200, {}, stub_data] }
      end
      
      def mock_timeout_error(endpoint)
        stub_call(:get, endpoint_for(endpoint)) do
          raise Faraday::TimeoutError
        end
      end

      def endpoint_for(method)
        "http://www.example.org/#{method}"
      end
    end
  end
end
