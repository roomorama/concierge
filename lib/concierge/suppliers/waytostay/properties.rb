module Waytostay
  #
  # Handles the fetching of properties from waytostay
  #
  module Properties

    ENDPOINT = "/properties/:property_reference".freeze
    INDEX_ENDPOINT = "/properties".freeze
    # The default number of properties per page returned from waytostay's /properties endpoint
    # This is used as the batch size when fetching properties, to prevent multiple page responses
    PER_PAGE = 25

    FIELD_MAPPINGS = {
      identifier:                "reference",
      title:                     "general.name",
      description:               "descriptions.description",
      type:                      "general.type",  # Currently all are "Apartment"
      lat:                       "location.coord.lat",
      lng:                       "location.coord.lng",
      number_of_bedrooms:        "general.bedrooms",
      number_of_bathrooms:       "general.bathrooms",
      surface:                   "general.sqm",
      max_guests:                "general.sleeps",
      minimum_stay:              "general.min_stay_default",
      check_in_time:             "general.checkin_time",
      check_out_time:            "general.checkout_time",
      currency:                  "payment.currency",
      nightly_rate:              "payment.lowest_rate",
      security_deposit_amount:   "payment.damage_deposit",
      security_deposit_currency: "payment.currency",
    }.freeze

    REQUIRED_RESPONSE_KEYS = (FIELD_MAPPINGS.values +
      [ "facilities_amenities.overview", "facilities_amenities.rooms", "payment.fees",
      "general.permissions", "services"]).freeze

    # A wrapper class for fetching properties with batch cache.
    # The objective is to minimize the number of requests
    #
    class BatchedPropertyFetcher

      # Loads all ids into memory using the client
      #
      def initialize(client, ids)
        @properties_cache_result = fetch_all(client, ids)
      end

      # Returns a Result
      # - wrapping a property if found
      # - with error if fetch_all had some error
      # - :not_found if there were no error in fetching, and the property ref wasn't found
      #
      def fetch(property_ref)
        return @properties_cache_result unless @properties_cache_result.success?

        @properties_cache_result.value.find do |p|
          p.value&.identifier == property_ref
        end || property_not_found_error
      end

      private

      # Loads all ids, 25(the amount per page) at a time
      #
      def fetch_all(client, ids)
        properties = []
        ids.each_slice(PER_PAGE) do |batch|
          result = client.get_properties_by_ids(batch)
          return result unless result.success?
          properties << result.value
        end
        Result.new(properties.flatten)
      end
    end

    def get_property_from_batch(property_ref, ids)
      @batched_fetcher ||= BatchedPropertyFetcher.new(self, ids)
      @batched_fetcher.fetch(property_ref)
    end

    # Always returns a +Result+ wrapped +Roomorama::Property+.
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, a generic error message is sent back to the caller.
    # No failure is logged. The failure anouncement should be done by caller. This
    # method is expected to be only called by +Workers:Suppliers::Waytostay+
    #
    def get_property(ref)
      result = oauth2_client.get(
        build_path(ENDPOINT, property_reference: ref),
        headers: headers)

      return result unless result.success?
      parse_property(Concierge::SafeAccessHash.new(result.value))
    end

    # Always returns a +Result+ wrapped array of +Roomorama::Property+.
    # Caller should only use this with a batch of 25 properties each time to avoid
    # having to fetch multiple pages, and to avoid `414 Request-URI Too Large`
    #
    def get_properties_by_ids(ids)
      result = oauth2_client.get(
        INDEX_ENDPOINT,
        params: { references: ids.join(","),
                  payment_option: Waytostay::Client::SUPPORTED_PAYMENT_METHOD},
        headers: headers)
      return result unless result.success?
      response = Concierge::SafeAccessHash.new(result.value)
      wrapped_properties = response.get("_embedded.properties").collect do |property_hash|
        parse_property(Concierge::SafeAccessHash.new(property_hash))
      end
      Result.new(wrapped_properties)
    end

    # Returns a +Result+ wrapping an array of +Result+ wrapped +Roomorama::Property+
    # and the next page number. Caller should call this method again with the returned
    # next page number until it is nil.
    #
    # This retrieves the current properties on waytostay that is active with supported
    # payment method.
    # See https://apis.sandbox.waytostay.com:25443/doc/swagger/WaytostayApi-v4#!/Properties/get_properties
    #
    # All properties returned here is to be published with Roomorama
    #
    # Example:
    #
    #   new_page = 1
    #   while !new_page.nil?
    #     result, new_page = get_active_properties(new_page)
    #     if result.success?
    #       import_multiple_properties(result.value)
    #     end
    #   end
    #
    def get_active_properties(current_page=1)
      result = oauth2_client.get(
        INDEX_ENDPOINT,
        params: { page: current_page, payment_option: "full_payment", active: true },
        headers: headers)
      return result unless result.success?
      response = Concierge::SafeAccessHash.new(result.value)
      wrapped_properties = response.get("_embedded.properties").collect do |property_hash|
        parse_property(Concierge::SafeAccessHash.new(property_hash))
      end
      next_page = current_page + 1 if current_page < response.get("page_count")
      return Result.new(wrapped_properties), next_page
    end

    private

    # Returns a +Roomorama::Property+ or nil from a +Concierge::SafeAccessHash+
    def parse_property(safe_hash)
      if safe_hash.get("active") == true
        parse_active_property(safe_hash)
      else
        Result.new inactive_property(safe_hash)
      end
    end

    def inactive_property(response)
      Roomorama::Property.new(response.get("reference")).tap do |property|
        property.disabled = true
      end
    end

    def parse_active_property(response)
      missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
      if missing_keys.empty?
        property = Roomorama::Property.new(response.get("reference"))
        property_attributes_from(response).each do |key, value|
          property[key] = value unless value.nil?
        end
        Result.new(property)
      else
        augment_missing_fields(missing_keys)
        Result.error(:unrecognised_response, "Missing keys: #{missing_keys}")
      end
    end

    # Returns params to initialize a Roomorama::Property from a SafeAccessHash
    def property_attributes_from(response)
      attr = {}
      FIELD_MAPPINGS.each do |roomorama_field, waytostay_field|
        attr[roomorama_field] = response.get(waytostay_field)
      end
      attr.merge!({
        surface_unit:         "metric",
        default_to_available: true,
        cancellation_policy:  "strict",
        instant_booking:      true
      })
      attr.merge! parse_floors(response)
      attr.merge! parse_permissions(response)
      attr.merge! parse_number_of_beds(response)
      attr.merge! parse_amenities(response)
      attr.merge! parse_approximate_rates(response)
      attr.merge! parse_security_deposit_method(response)
      attr.merge! parse_extra_location_info(response)

      attr.merge! parse_property_state(response)
    end

    def parse_extra_location_info(response)
      {
        country_code: response.get("location.country.iso"),
        address:      response.get("location.address.address"),
        city:         response.get("location.city.name"),
        postal_code:  response.get("location.address.postcode")
      }
    end

    def parse_approximate_rates(response)
      {
        weekly_rate:  response.get("payment.lowest_rate") * 7,
        monthly_rate: response.get("payment.lowest_rate") * 30,
      }
    end

    def parse_property_state(response)
      payment_supported = response.get("payment.payment_options")
                            .include?  Waytostay::Client::SUPPORTED_PAYMENT_METHOD
      active = response.get("active")
      { disabled: !payment_supported || !active }
    end

    def parse_floors(response)
      floors = response.get("general.floors")
      { floor:floors.first["name"] }
    end

    # Extracts `smoking_allowed`, `pets_allowed`
    def parse_permissions(response)
      {
        pets_allowed:     response.get("general.permissions.pets") == "allowed",
        smoking_allowed:  response.get("general.permissions.smoking") == "allowed",
      }
    end

    # Parse the following into bed counts:
    # "bedding_summary": [
    #   "1 single sofa bed",
    #   "2 double bed",
    #   "4 single bed",
    #   "1 double sofa bed"
    # ],
    def parse_number_of_beds(response)

      summary = response.get("general.bedding_summary")
      summary_string = summary&.map(&:to_s)&.join(", ").to_s
      # matches both single sofa and double sofa:
      sofa_beds = 0
      summary_string.scan(/([0-9]*) \w+ sofa bed/) do |match|
        sofa_beds += match.first.to_i
      end

      double_matches = /([0-9]*) double bed/.match(summary_string)
      single_matches = /([0-9]*) single bed/.match(summary_string)
      {
        number_of_double_beds: double_matches.nil? ? 0 : double_matches[1].to_i,
        number_of_single_beds: single_matches.nil? ? 0 : single_matches[1].to_i,
        number_of_sofa_beds:   sofa_beds
      }
    end

    def parse_security_deposit_method(response)
      methods = Array(response.get("payment.damage_deposit_payment_methods"))
      if methods.find { |m| m["name"] == "cash" }
        { security_deposit_type: "cash" }
      elsif methods.find { |m| m["name"] == "credit card details will be taken" }
        { security_deposit_type: "credit_card_auth" }
      elsif methods.find { |m| m["name"] == "traveller’s cheques" }
        { security_deposit_type: "check" }
      else
        {}
      end
    end

    def parse_amenities(response)
      roomorama_amenities = []
      amenities = Array(response.get("facilities_amenities.overview"))

      amenities.each do |wts_amenity|
        if wts_amenity["checked"] && AMENITIES_MAPPINGS.include?(wts_amenity["name"])
         roomorama_amenities << AMENITIES_MAPPINGS[wts_amenity["name"]]
        end
      end

      # kitchen
      if response.get("facilities_amenities.rooms").any? { |r| r["type"] == "Kitchen"}
        roomorama_amenities << "kitchen"
      end

      # wifi
      if response.get("services").any? { |s| s["name"] == "internet via WiFi" && !s["on_request"] && !s["extra_cost"] }
        roomorama_amenities << "wifi"
      end

      # free_cleaning
      unless response.get("payment.fees").any? {|f| f["name"] == "cleaning fee" && f["fee"] > 0}
        roomorama_amenities << "free_cleaning"
      end

      # bed_linen_and_towels
      has_bed_linen = amenities.any? { |a| a["name"] == "Bed linen" && a["checked"] }
      has_towel = amenities.any? { |a| a["name"] == "Towels" && a["checked"] }
      if has_bed_linen && has_towel
        roomorama_amenities << "bed_linen_and_towels"
      end

      { amenities: roomorama_amenities }
    end

    AMENITIES_MAPPINGS = {
      "Internet"         => "internet",
      "International TV" => "cabletv",
      "TV"               => "tv",
      "Parking"          => "parking",
      "Air conditioning" => "airconditioning",
      "Washing machine"  => "laundry",
      "Swimming pool"    => "pool",
      "Lift"             => "elevator",
      "Balcony"          => "balcony",
      "Terrace"          => "outdoor_space"
    }

  end

  def property_not_found_error
    Result.error(:not_found, "Property not found with id `#{property_ref}`")
  end
end

