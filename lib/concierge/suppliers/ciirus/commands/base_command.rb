module Ciirus
  module Commands
    # +Ciirus::Commands::BaseCommand+
    #
    # Base class for all call Ciirus API commands. Each child should
    # implement two methods:
    #  - call(params) - API call execution with returning +Result+
    #  - operation_name - name of API method
    class BaseCommand
      VERSION = '15.025'
      PATH = "/CiirusXML.#{VERSION}.asmx"

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      protected

      def xml_builder
        @xml_builder ||= Ciirus::XMLBuilder.new(credentials)
      end

      def response_parser
        @response_parser ||= Ciirus::ResponseParser.new
      end

      def client
        @client ||= API::Support::SOAPClient.new(options)
      end

      def options
        wsdl = "#{credentials.url}/#{PATH}?wsdl"
        {
            wsdl:                 wsdl,
            env_namespace:        :soap12,
            namespace_identifier: nil
        }
      end

      def remote_call(message)
        client.call(operation_name, message: message)
      end

      def valid_result?(hash)
        # TODO: implement after research error cases from Ciirus API
        true
      end

      def error_result(hash)
        # TODO: implement after research error cases from Ciirus API
        true
      end

      def to_array(something)
        if something.is_a? Hash
          [something]
        else
          Array(something)
        end
      end

      def to_safe_hash(usual_hash)
        Concierge::SafeAccessHash.new(usual_hash)
      end
    end
  end
end