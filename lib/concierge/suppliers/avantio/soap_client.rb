module Avantio
  # +Avantio::Commands::SoapClient+
  #
  # Class implements calls to Avantio SOAP API
  #
  # Usage:
  #
  #   client = SoapClient.new
  #   msg = Avantio::XMLBuilder.new(credentials).booking_price
  #   result = client.call(msg)
  class SoapClient
    WSDL = 'http://ws.avantio.com/soap/vrmsConnectionServices.php?wsdl'

    def call(message)
      client.call(operation_name, message: message)
    end

    protected

    def client
      @client ||= Concierge::SOAPClient.new(options)
    end

    def options
      {
        wsdl:         WSDL,
        open_timeout: 10,
        read_timeout: 10
      }
    end
  end
end