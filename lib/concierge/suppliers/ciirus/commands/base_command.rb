module Ciirus
  module Commands
    # +Ciirus::Commands::BaseCommand+
    #
    # Base class for all call Ciirus API commands. Each child should
    # implement two methods:
    #  - call(params) - API call execution with returning +Result+
    #  - operation_name - name of API method
    #
    # There are two API endpoints: general and additional, so
    # remote_call and additional_remote_call makes appropriate requests.
    class BaseCommand
      VERSION = '15.025'
      PATH = "/CiirusXML.#{VERSION}.asmx"
      ADDITIONAL_PATH = "/XMLAdditionalFunctions#{VERSION}.asmx"
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

      def client
        @client ||= Concierge::SOAPClient.new(options(PATH))
      end

      def additional_client
        @additional_client ||= Concierge::SOAPClient.new(options(ADDITIONAL_PATH))
      end

      def options(path)
        endpoint = "#{credentials.url}/#{path}"
        wsdl     = "#{endpoint}?wsdl"
        {
          wsdl:          wsdl,
          env_namespace: :soap,
          endpoint:      endpoint,
          open_timeout:  10,
          read_timeout:  20
        }
      end

      def remote_call(message)
        call_client(client, message)
      end

      def additional_remote_call(message)
        call_client(additional_client, message)
      end

      def call_client(client, message)
        client.call(operation_name, message: message, attributes: {'xmlns' => 'http://xml.ciirus.com/'})
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