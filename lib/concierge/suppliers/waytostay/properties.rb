module Waytostay
  #
  # Handles all fetching from waytostay
  #
  module Properties

    ENDPOINT = "/properties/:property_reference"

    FIELD_MAPPINGS = {
        identifier:          "reference",
        title:               "general.name",
        description:         "descriptions.description",
        type:                "general.type",
        country_code:        "location.country.iso",
        lat:                 "location.coord.lat",
        lng:                 "location.coord.lng",
        number_of_bedrooms:  "general.bedrooms",
        number_of_bathrooms: "general.bathrooms",
        surface:             "general.sqm",
        max_guests:          "general.sleeps",
        minimum_stay:        "general.min_stay_default",
        check_in_time:       "general.checkin_time",
        check_out_time:      "general.checkout_time",
        currency:            "payment.currency",
      }

    REQUIRED_RESPONSE_KEYS = FIELD_MAPPINGS.values +
      [ "facilities_amenities.overview", "facilities_amenities.rooms", "payment.fees",
      "general.permissions", "services"]

    # Always returns a +Result+ wrapped +Roomorama::Property+.
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, a generic error message is sent back to the caller.
    # No failure is logged. The failure anouncement should be done by caller. This
    # method expected to be only ever called by +Workers:Synchronisation
    def get_property(ref)
      result = oauth2_client.get(
        build_path(ENDPOINT, property_reference: ref),
        headers: headers
      )

      parse_property(result)
    end

    private

    # Returns a +Roomorama::Property+ or nil from a +Result+
    def parse_property(result)
      if result.success?
        response = Concierge::SafeAccessHash.new(result.value)

        missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
        if missing_keys.empty?
          property = Roomorama::Property.new(response.get("reference"))
          property_attributes_from(response).each do |key, value|
            property[key] = value if value
          end
          Result.new(property)
        else
          augment_missing_fields(missing_keys)
          Result.error(:unrecognised_response)
        end

      else
        result
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
        cancellation_policy:  "strict", #TODO: review cancellation policy
        instant_booking:      true
      })
      attr.merge! parse_floors(response)
      attr.merge! parse_permissions(response)
      attr.merge! parse_services(response)
      attr.merge! parse_number_of_beds(response)
      attr.merge! parse_amenities(response)
    end

    def parse_floors(response)
      floors = response.get("general.floors")
      {
        floor:floors.first["name"]
      }
    end

    # Extracts `smoking_allowed`, `pets_allowed`
    def parse_permissions(response)
      {
        pets_allowed:     response.get("general.permissions.pets") == "allowed",
        smoking_allowed:  response.get("general.permissions.smoking") == "allowed",
        parties_allowed:  response.get("general.permissions.parties") == "allowed",
        children_allowed: response.get("general.permissions.children") == "allowed",
        young_allowed:    response.get("general.permissions.young") == "allowed",
      }
    end

    # Extracts `services_cleaning[rate/required]`
    def parse_services(response)
      cleaning_fees = response.get("payment.fees")
                              .select { |x| x["name"]=="cleaning fee" }
                              .collect { |x| x["fee"] }
      total_cleaning_fee = cleaning_fees.reduce(&:+)
      {
        services_cleaning:          cleaning_fees.count > 0,
        services_cleaning_rate:     total_cleaning_fee,
        services_cleaning_required: true # have to pay fee to wts. TODO: check what this means in roomroama
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
      summary = response.get("general.bedding_summary").join(", ")
      # matches both single sofa and double sofa:
      sofa_beds = 0
      summary.scan(/([0-9]*) \w+ sofa bed/) do |match|
        sofa_beds += match.first.to_i
      end
      {
        number_of_double_beds: /([0-9]*) double bed/.match(summary)[1].to_i,
        number_of_single_beds: /([0-9]*) single bed/.match(summary)[1].to_i,
        number_of_sofa_beds:   sofa_beds
      }
    end

    def parse_amenities(response)
      roomorama_amenities = []
      amenities = response.get("facilities_amenities.overview")
      AMENITIES_MAPPINGS.each do |amenity, key|
         if amenities.any? { |a| a["name"]==key && a["checked"] }
           roomorama_amenities << amenity.to_s
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
        "internet":             "Internet",
        "cabletv":              "International TV",
        "tv":                   "TV",
        "parking":              "Parking",
        "airconditioning":      "Air conditioning",
        "laundry":              ["Washing machine"],
        "pool":                 "Swimming pool",
        "elevator":             "Lift",
        "balcony":              "Balcony",
        "outdoor_space":        "Terrace",
        # "breakfast":          "waytostay do not support",
        # "doorman":            "waytostay do not support",
        # "wheelchairaccess":   "waytostay do not support",
        # "gym":                "waytostay do not support",
      }

  end
end

