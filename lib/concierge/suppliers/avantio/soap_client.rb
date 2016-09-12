module Avantio
  # +Avantio::Commands::SoapClient+
  #
  # Class implements calls to Avantio SOAP API
  #
  # Usage:
  #
  #   client = SoapClient.new
  #   msg = Avantio::XMLBuilder.new(credentials).booking_price
  #   result = client.call(:get_booking_price, msg)
  class SoapClient
    WSDL = 'http://ws.avantio.com/soap/vrmsConnectionServices.php?wsdl'

    def call(method, message)
      client.call(method, message: message)
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
