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
      ENDPOINT = "http://xml.ciirus.com/CiirusXML.#{VERSION}.asmx"

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
        endpoint = [credentials.url, ENDPOINT].join('/')
        {
            wsdl:                 endpoint + '?wsdl',
            env_namespace:        :soapenv,
            namespace_identifier: nil,
            open_timeout:         5,
            read_timeout:         10
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
    end
  end
end