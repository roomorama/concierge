module AtLeisure
  # +AtLeisure::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # Usage
  #
  #   importer = AtLeisure::Importer.new(credentials)
  #   importer.fetch_properties
  #
  #   => #<Result:0x007ff5fc624dd8 @result=[{'HouseCode' => 'XX-12345-67', ...}, ...]
  class Importer

    ENDPOINT_METHODS = {
      properties_list: "ListOfHousesV1",
      properties_data: "DataOfHousesV1",
      layout_items:    "ReferenceLayoutItemsV1"
    }

    LAYERS = %w(BasicInformationV3 MediaV1 LanguagePackDEV3 LanguagePackENV3 LanguagePackESV3 PropertiesV1 LayoutExtendedV2 DistancesV1 AvailabilityPeriodV1 MinMaxPriceV1)

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # this method retrieves the list of properties
    def fetch_properties
      endpoint = ENDPOINT_METHODS.fetch(:properties_list)
      client_for(endpoint).invoke(endpoint, authentication_params)
    end

    # fetches references information for properties. Return result with array
    def fetch_layout_items
      endpoint = ENDPOINT_METHODS.fetch(:layout_items)
      client_for(endpoint).invoke(endpoint, authentication_params)
    end

    # fetches extended information for properties by their identifiers. Return result with list of properties with
    # additional data which were pointed in +layers+
    def fetch_data(properties, layers: LAYERS)
      params   = { 'HouseCodes' => identifiers(properties), 'Items' => Array(layers) }
      endpoint = ENDPOINT_METHODS.fetch(:properties_data)

      client_for(endpoint).invoke(endpoint, params.merge(authentication_params))
    end

    private

    def client_for(method)
      endpoint = "https://#{method.downcase}.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm"
      API::Support::JSONRPC.new(endpoint, client_options: { timeout: 30 })
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


