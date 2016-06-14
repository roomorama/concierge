module AtLeisure
  class Importer

    ENDPOINT_METHODS = {
      properties_list: "ListOfHousesV1",
      properties_data: "DataOfHousesV1",
      layout_items:    "ReferenceLayoutItemsV1"
    }

    LAYERS = [
      "BasicInformationV3",
      "MediaV1",
      "LanguagePackDEV3",
      "LanguagePackENV3",
      "LanguagePackESV3",
      "PropertiesV1",
      "LayoutExtendedV2",
      "DistancesV1",
      "AvailabilityPeriodV1",
      "MinMaxPriceV1"
    ]

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def fetch_properties
      endpoint = ENDPOINT_METHODS.fetch(:properties_list)
      client_for(endpoint).invoke(endpoint, authentication_params)
    end


    def fetch_layout_items
      endpoint = ENDPOINT_METHODS.fetch(:layout_items)
      client_for(endpoint).invoke(endpoint, authentication_params)
    end

    def fetch_data(properties, layers: LAYERS)
      params   = { 'HouseCodes' => identifiers(properties), 'Items' => Array(layers) }
      endpoint = ENDPOINT_METHODS.fetch(:properties_data)

      client_for(endpoint).invoke(endpoint, params.merge(authentication_params))
    end

    private

    def client_for(method)
      endpoint = "https://#{method.downcase}.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm"
      API::Support::JSONRPC.new(endpoint)
    end

    def authentication_params
      {
        'WebpartnerCode'     => credentials.username,
        'WebpartnerPassword' => credentials.password
      }
    end

    def identifiers(properties)
      properties.map { |property| property['HouseCode'] }
    end

  end
end


