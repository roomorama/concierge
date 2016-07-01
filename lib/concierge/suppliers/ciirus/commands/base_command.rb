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
      ROOMORAMA_DATE_FORMAT = "%Y-%m-%d"
      CIIRUS_DATE_FORMAT = "%d %b %Y"

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
        @client ||= Concierge::SOAPClient.new(options)
      end

      def options
        wsdl = "#{credentials.url}/#{PATH}?wsdl"
        {
            wsdl:                 wsdl,
            env_namespace:        :soap12,
            namespace_identifier: nil,
            soap_version:         2
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

      def to_safe_hash(usual_hash)
        Concierge::SafeAccessHash.new(usual_hash)
      end

      # Converts date string to Ciirus expected format
      def convert_date(date)
        Date.strptime(date, ROOMORAMA_DATE_FORMAT).strftime(CIIRUS_DATE_FORMAT)
      end

      def mismatch(message, backtrace)
        response_mismatch = Concierge::Context::ResponseMismatch.new(
          message:   message,
          backtrace: backtrace
        )

        Concierge.context.augment(response_mismatch)
      end
    end
  end
end