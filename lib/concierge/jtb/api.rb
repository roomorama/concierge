module JTB
  class API
    ENDPOINTS = { quote_price: 'GA_HotelAvail_v2013', create_booking: 'GA_HotelRes_v2013', cancel_booking: 'GA_Cancel_v2013' }

    attr_reader :credentials, :message

    def initialize(credentials)
      @credentials = credentials
    end

    def quote_price(params)
      @message = builder.quote_price(params)
      caller(:quote_price).call(:gby010, message: @message.to_xml)
    end

    private

    def caller(endpoint)
      @caller ||= ::API::Support::SOAPClient.new(options_for(endpoint))
    end

    def builder
      XMLBuilder.new(credentials)
    end

    def uri
      Hanami.env == 'production' ?
        'https://www.jtbgenesis.com/genesis2/services' :
        'https://trial-www.jtbgenesis.com/genesis2-demo/services'
    end

    def options_for(endpoint)
      endpoint = [uri, ENDPOINTS[endpoint]].join('/')
      {
        wsdl:                 endpoint + '?wsdl',
        env_namespace:        :soapenv,
        namespace_identifier: 'jtb',
        endpoint:             endpoint
      }
    end
  end
end
