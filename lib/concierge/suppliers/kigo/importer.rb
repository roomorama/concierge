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

    PROPERTIES_LIST     = 'listProperties2'
    PROPERTY_DATA       = 'readProperty2'
    PRICES              = 'readPropertyPricingSetup'
    PRICES_DIFF         = 'diffPropertyPricingSetup'
    AVAILABILITIES      = 'listPropertyAvailability'
    AVAILABILITIES_DIFF = 'diffPropertyAvailability'
    RESERVATIONS        = 'listPropertyCalendarReservations'
    IMAGE           = 'readPropertyPhotoFile'

    # references
    AMENITIES           = 'listKigoPropertyAmenities'
    PROPERTY_TYPES      = 'listKigoPropertyTypes'

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

    def fetch_prices_diff(id)
      fetch(PRICES_DIFF, { DIFF_ID: id })
    end

    def fetch_availabilities(id, start_date: Date.today, end_date: one_year_from_today)
      params = {
        PROP_ID:         id,
        LIST_START_DATE: start_date,
        LIST_END_DATE:   end_date
      }
      fetch(AVAILABILITIES, params)
    end

    def fetch_availabilities_diff(id)
      fetch(AVAILABILITIES_DIFF, { DIFF_ID: id })
    end

    def fetch_reservations(id, start_date: Date.today, end_date: one_year_from_today)
      params = {
        PROP_ID:         id,
        LIST_START_DATE: start_date,
        LIST_END_DATE:   end_date
      }
      fetch(RESERVATIONS, params)
    end

    # references helps us to match data by their names instead of using ids
    def fetch_references
      amenities_result = fetch(AMENITIES)
      return amenities_result unless amenities_result.success?

      property_types_result = fetch(PROPERTY_TYPES)
      return property_types_result unless property_types_result.success?

      references = { 'amenities' => amenities_result.value, 'property_types' => property_types_result.value }
      Result.new(references)
    end

    def fetch_image(prop_id, image_id)
      fetch(IMAGE, PROP_ID: prop_id, PHOTO_ID: image_id)
    end

    private

    def fetch(request_method, params = nil)
      headers = { "Content-Type" => "application/json" }
      result  = http.post(endpoint(request_method), json_encode(params), headers)

      return result unless result.success?

      response = result.value
      payload  = json_decode(response.body)

      return payload unless payload.success?

      case payload.value['API_RESULT_CODE']
        when 'E_OK'     then Result.new(payload.value['API_REPLY'])
        when 'E_NOSUCH' then Result.error(:invalid_input_data)
        when 'E_INPUT'  then Result.error(:record_not_found)
      end
    end

    def http
      @http ||= request_handler.http_client
    end

    def endpoint(request_method)
      request_handler.endpoint_for(request_method)
    end

    def one_year_from_today
      Date.today + 365
    end
  end
end


