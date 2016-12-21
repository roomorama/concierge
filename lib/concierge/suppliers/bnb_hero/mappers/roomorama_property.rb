module BnbHero
  module Mappers
    class RoomoramaProperty

      # Mapping from bnbhero's subtype to roomorama's type and subtype
      PROPERTY_TYPE_MAPPINGS = {
        "villa"             => {type: "house", subtype: "villa"},
        "hanok"             => {type: "house"},
        "house"             => {type: "house"},
        "guest_house"       => {type: "house"},
        "bed_and_breakfast" => {type: "bnb"},
        "home_stay"         => {type: "bnb"},
        "apartment"         => {type: "apartment"},
      }

      # Mapping from roomorama field name to bnbhero's field name
      RM_BBH_FIELD_MAPPINGS = {
        "identifier": "identifier",

        "country_code": "country_code",
        "lat":         "lat",
        "lng":         "lng",

        "nightly_rate": "nightly_rate",
        "weekly_rate":  "weekly_rate",
        "monthly_rate": "monthly_rate",
        "max_guests":   "max_guests",
        "minimum_stay": "minimum_stay",
        "base_guests":  "rate_base_max_guests",

        "postal_code": "postal_code",
        "address":     "address",
        "city":        "city",

        "number_of_bedrooms":    "number_of_bedrooms",
        "number_of_bathrooms":   "number_of_bathrooms",
        "number_of_double_beds": "number_of_double_beds",

        "amenities":        "amenities",
        "smoking_allowed":  "smoking_allowed",
        "pets_allowed":     "pets_allowed",
        "children_allowed": "children_allowed",
        "check_in_time":    "check_in_time",
        "check_out_time":   "check_out_time",

        "services_airport_pickup":    "services_airport_pickup",
        "services_concierge":         "services_concierge",
        "services_cleaning":          "services_cleaning",
        "services_cleaning_required": "services_cleaning_required",
        "services_cleaning_rate":     "services_cleaning_rate",

        "multi_unit":           "multi_unit",
        "surface_unit":         "surface_unit",
        "currency":             "currency",
        "default_to_available": "default_to_available",
        "cancellation_policy":  "cancellation_policy",
      }

      def map(hash)
        data = Concierge::SafeAccessHash.new(hash)
        property = Roomorama::Property.new(data.get("identifier"))
        property_attributes_from(data).each do |key, value|
          property[key] = value
        end

        property = add_translations(property, data)

        parse_images(data).each do |image|
          property.add_image(image)
        end

        Result.new(property)
      end

      private

      def add_translations(property, data)
        property.tap do |p|
          p.title = data.get("content.en.title")
          p.description = data.get("content.en.description")
          p.check_in_instructions = data.get("content.en.check_in_instructions")

          p.zh.title = data.get("content.zh-CN.title")
          p.zh.description = data.get("content.zh-CN.description")
          p.zh.check_in_instructions = data.get("content.zh-CN.check_in_instructions")

          p.zh_tw.title = data.get("content.zh-TW.title")
          p.zh_tw.description = data.get("content.zh-TW.description")
          p.zh_tw.check_in_instructions = data.get("content.zh-TW.check_in_instructions")
        end
      end

      def parse_images(data)
        images = []
        data.get("images")[0].each do |key, image|
          rmrm_image = Roomorama::Image.new(image["identifier"])
          rmrm_image.url = URI.escape(image["url"])
          rmrm_image.caption = image["caption"]
          rmrm_image.position = image[key]
          images << rmrm_image
        end
        images
      end

      def property_attributes_from(data)
        attr = {}
        RM_BBH_FIELD_MAPPINGS.each do |rm_field, bbh_field|
          attr[rm_field] = data.get(bbh_field)
        end
        attr[:extra_guest_surcharge] = data["extra_guest_surcharge"] unless data["extra_guest_surcharge"].nil?
        attr[:surface] = data["surface"].to_f if data["surface"].to_f > 0.0
        attr[:instant_booking] = false
        attr.merge! security_deposit(data)
        attr.merge! type_and_subtype(data)
      end

      def type_and_subtype(data)
        PROPERTY_TYPE_MAPPINGS[data["subtype"]]
      end

      def security_deposit(data)
        {}.tap do |attr|
          if data.get("security_deposit_amount").to_f > 0.0
            attr["security_deposit_amount"] = attr["security_deposit_amount"].to_f
            attr["security_deposit_type"] = attr["security_deposit_type"]
            attr["security_deposit_currency_code"] = attr["security_deposit_currency_code"]
          end
        end
      end

    end
  end
end
