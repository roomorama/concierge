module Kigo
  # +Kigo::Importer+
  #
  # This class is responsible for wrapping the logic related to fetching
  # properties from Kigo, parsing the response, and building the +Result+
  # object.
  #
  # Usage
  #
  #   importer = Kigo::Importer.new(credentials)
  #   importer.fetch_properties
  #
  #   => #<Result:0x007ff5fc624dd8 @result=[{"PROP_ID"=>111985, "PROP_PROVIDER"=>{...}}, ...]
  class Importer
    include Concierge::JSON

    PROPERTIES_LIST = 'listProperties2'
    PROPERTY_DATA   = 'readProperty2'
    PRICES          = 'readPropertyPricingSetup'
    AVAILABILITIES  = 'listPropertyAvailability'
    RESERVATIONS    = 'listPropertyCalendarReservations'

    # references
    AMENITIES       = 'listKigoPropertyAmenities'
    PROPERTY_TYPES  = 'listKigoPropertyTypes'

    attr_reader :credentials, :request_handler

    def initialize(credentials, request_handler)
      @credentials     = credentials
      @request_handler = request_handler
    end

    def fetch_properties
      fetch(PROPERTIES_LIST)
    end

    def fetch_data(id)
      fetch(PROPERTY_DATA, { PROP_ID: id })
    end

    def fetch_prices(id)
      fetch(PRICES, { PROP_ID: id })
    end

    def fetch_availabilities(id, start_date:, end_date:)
      params = {
        PROP_ID:         id,
        LIST_START_DATE: start_date,
        LIST_END_DATE:   end_date
      }
      fetch(AVAILABILITIES, params)
    end

    def fetch_reservations(id, start_date:, end_date:)
      params = {
        PROP_ID:         id,
        LIST_START_DATE: start_date,
        LIST_END_DATE:   end_date
      }
      fetch(RESERVATIONS, params)
    end

    # references helps us to match data by their names instead of using ids
    def fetch_references
      Result.new({
                   'amenities'      => fetch(AMENITIES).value,
                   'property_types' => fetch(PROPERTY_TYPES).value
                 })
    end

    private

    def fetch(request_method, params = nil)
      result = http.post(endpoint(request_method), json_encode(params), headers)

      if result.success?
        response = result.value
        payload  = json_decode(response.body).value
        Result.new(payload['API_REPLY'])
      else
        result
      end
    end

    def http
      @http ||= request_handler.http_client
    end

    def endpoint(request_method)
      request_handler.endpoint_for(request_method)
    end

    def headers
      { "Content-Type" => "application/json" }
    end

  end
end


