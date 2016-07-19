module Kigo
  # +Kigo::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # Usage
  #
  #   importer = Kigo::Importer.new(credentials)
  #   importer.fetch_properties
  #
  #   => #<Result:0x007ff5fc624dd8 @result=[{"PROP_ID"=>111985, "PROP_PROVIDER"=>{...}}, ...]
  class Importer
    PROPERTIES_LIST = 'listProperties2'
    PROPERTY_DATA   = 'readProperty2'
    PRICES          = 'readPropertyPricingSetup'
    AVAILABILITIES  = 'listPropertyAvailability'
    RESERVATIONS    = 'listPropertyCalendarReservations'

    # references
    AMENITIES       = 'listKigoPropertyAmenities'
    PROPERTY_TYPES  = 'listKigoPropertyTypes'
    FEE_TYPES       = 'listKigoFeeTypes'
    BED_TYPES       = 'listKigoPropertyBedTypes'

    attr_reader :credentials, :request_handler

    def initialize(credentials, request_handler)
      @credentials     = credentials
      @request_handler = request_handler
    end

    def fetch_properties
      http.post(endpoint(PROPERTIES_LIST))
    end

    def fetch_data(id)
      http.post(endpoint(PROPERTY_DATA), { PROP_ID: id })
    end

    def fetch_prices(id)
      http.post(endpoint(PRICES), { PROP_ID: id })
    end

    def fetch_availabilities(id, start_date:, end_date:)
      http.post(endpoint(AVAILABILITIES), {
        PROP_ID:         id,
        LIST_START_DATE: start_date,
        LIST_END_DATE:   end_date
      })
    end

    def fetch_reservations(id, start_date:, end_date:)
      http.post(endpoint(RESERVATIONS), {
        PROP_ID:         id,
        LIST_START_DATE: start_date,
        LIST_END_DATE:   end_date
      })
    end

    def fetch_references
      {
        amenities:      http.post(AMENITIES),
        fee_types:      http.post(FEE_TYPES),
        property_types: http.post(PROPERTY_TYPES),
        bed_types:      http.post(BED_TYPES)
      }
    end

    private

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


