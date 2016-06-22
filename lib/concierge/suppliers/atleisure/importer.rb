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
    TIMEOUT          = 1000 # seconds
    ENDPOINT_METHODS = {
      properties_list: "ListOfHousesV1",
      properties_data: "DataOfHousesV1",
      layout_items:    "ReferenceLayoutItemsV1"
    }

    # each layer extends property's data accordingly its responsibility
    LAYERS = %w(BasicInformationV3 MediaV2 PropertiesV1 LayoutExtendedV2 AvailabilityPeriodV1 CostsOnSiteV1)
    LANGUAGES = %w(en de es)

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # retrieves the list of properties
    def fetch_properties
      endpoint = ENDPOINT_METHODS.fetch(:properties_list)
      client_for(endpoint).invoke(endpoint, authentication_params)
    end

    # fetches references information for properties. Return result with list of properties
    def fetch_layout_items
      endpoint = ENDPOINT_METHODS.fetch(:layout_items)
      client_for(endpoint).invoke(endpoint, authentication_params)
    end

    # fetches extended information for properties by their identifiers. Return result with list of properties with
    # additional data which were pointed in +layers+
    def fetch_data(identifiers, layers: default_layers)
      params   = { 'HouseCodes' => identifiers, 'Items' => Array(layers) }
      endpoint = ENDPOINT_METHODS.fetch(:properties_data)

      client_for(endpoint).invoke(endpoint, params.merge(authentication_params))
    end

    private

    def client_for(method)
      endpoint = "https://#{method.downcase}.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm"
      API::Support::JSONRPC.new(endpoint, client_options: { timeout: TIMEOUT })
    end

    def authentication_params
      {
        'WebpartnerCode'     => credentials.username,
        'WebpartnerPassword' => credentials.password
      }
    end

    def default_layers
      LAYERS + language_layers
    end

    def language_layers
      LANGUAGES.map {|lang| "LanguagePack#{lang.upcase}V4"}
    end

  end
end


