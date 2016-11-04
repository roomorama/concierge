module THH
  module Commands
    # +THH::Commands::BaseCommand+
    #
    # Base class for all call THH API commands. Each child should
    # implement:
    #  - action - name of API action
    class BaseFetcher
      TIMEOUT = 10

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def api_call(params)
        additional_params = {
          'action' => action,
          'key'    => credentials.key
        }
        result = http.get('', params.merge(additional_params), headers)

        return result unless result.success?

        to_safe_hash(result.value.body)
      end

      protected

      def action
        NotImplementedError
      end

      def timeout
        TIMEOUT
      end

      private

      def http
        @http_client ||= Concierge::HTTPClient.new(credentials.url, timeout: timeout)
      end

      def headers
        { "Content-Type" => "application/xml" }
      end

      def to_safe_hash(str)
        # Sometimes THH provides XML with syntax errors, to handle them
        # run Nokogiri parser in soft mode, convert result to xml string
        # and convert it to the hash
        xml = Nokogiri::XML(str)
        valid_xml = xml.to_s
        parser = Nori.new
        Result.new(Concierge::SafeAccessHash.new(parser.parse(valid_xml)))
      end
    end
  end
end
