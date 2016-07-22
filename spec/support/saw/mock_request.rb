module Support
  module SAW
    module MockRequest
      def mock_request(endpoint, filename)
        stub_data = read_fixture("saw/#{endpoint}/#{filename}.xml")
        stub_call(:post, endpoint_for(endpoint)) { [200, {}, stub_data] }
      end

      def mock_bad_xml_request(endpoint)
        stub_data = read_fixture("saw/bad_xml.xml")
        stub_call(:post, endpoint_for(endpoint)) { [200, {}, stub_data] }
      end

      def mock_timeout_error(endpoint)
        stub_call(:post, endpoint_for(endpoint)) do
          raise Faraday::TimeoutError
        end
      end

      def endpoint_for(method)
        "http://staging.servicedapartmentsworldwide.net/xml/#{method}.aspx"
      end
    end
  end
end
