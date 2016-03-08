require_relative 'xml_builder'

module JTB
  class API
    include JTB::XMLBuilder

    ENDPOINTS = { quote_price: 'GA_HotelAvail_v2013', create_booking: 'GA_HotelRes_v2013', cancel_booking: 'GA_Cancel_v2013' }

    attr_reader :message, :response

    def initialize(options)
      @id       = options[:id]
      @user     = options[:user]
      @password = options[:password]
      @company  = options[:company]
    end

    def quote_price(params)
      @message  = build_availabilities(params)
      @response = caller(:quote_price).call(:gby010, message: @message.to_xml)
      @response.body
    end


    private

    def caller(endpoint)
      Savon.client(options_for(endpoint))
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
