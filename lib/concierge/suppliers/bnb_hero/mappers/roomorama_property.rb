module BnbHero
  module Mappers
    class RoomoramaProperty

      # Mapping from bnbhero's type to roomorama's type and subtype
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
        "identifier": "id",

        "country_code": "country_code",
        "lat":         "lat",
        "lng":         "lng",

        "max_guests":            "max_guests",
        "minimum_stay":          "min_stay",
        "rate_base_max_guests":  "base_guests",
        "extra_guest_surcharge": "extra_guest_surcharge",

        "postal_code": "postal_code",
        "address":     "street_address",
        "city":        "city",

        "number_of_bedrooms":    "num_rooms",
        "number_of_bathrooms":   "num_bathrooms",
        "number_of_double_beds": "double_beds",

        "amenities":        "amenities",
        "smoking_allowed":  "conditions.smoking_allowed",
        "pets_allowed":     "conditions.pets_allowed",
        "children_allowed": "children_allowed",
        "check_in_time":    "check_in_time",
        "check_out_time":   "check_out_time",

        "services_airport_pickup":    "services.airport_port.available",
        "services_concierge":         "services.concierge.available",

        "multi_unit":           "multi_unit",
        "currency":             "currency",
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
          p.title                 = data.get("title.en")
          p.description           = data.get("description.en")
          p.check_in_instructions = data.get("check_in_instructions.en")

          p.zh.title                 = data.get("title.zh-CN")
          p.zh.description           = data.get("description.zh-CN")
          p.zh.check_in_instructions = data.get("check_in_instructions.zh-CN")

          p.zh_tw.title                 = data.get("title.zh-TW")
          p.zh_tw.description           = data.get("description.zh-TW")
          p.zh_tw.check_in_instructions = data.get("check_in_instructions.zh-TW")
        end
      end

      def parse_images(data)
        images = []
        data.get("images")[0].each do |key, image|
          url = URI.escape(image["url"])
          identifier = Digest::MD5.hexdigest(url)
          rmrm_image = Roomorama::Image.new(identifier)
          rmrm_image.url = url
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
        attr[:surface] = data["surface"].to_f if data["surface"].to_f > 0.0
        attr[:surface_unit] = "metric"
        attr[:default_to_available] = true
        attr[:services_cleaning] = false
        attr[:instant_booking] = false
        attr.merge! security_deposit(data)
        attr.merge! type_and_subtype(data)
        attr.merge! owner_info(data)
        attr.merge! rates(data)
        sanitize! attr
      end

      def rates(data)
        nightly = data["nightly_rate"].to_f
        weekly  = data["weekly_rate"].to_f
        weekly  = nightly * 7 if weekly == 0.0  # weekly maybe given as "null"
        monthly = data["monthly_rate"].to_f
        monthly = nightly * 30 if monthly == 0.0  # monthly maybe given as "null"
        {
          nightly_rate: nightly,
          weekly_rate:  weekly,
          monthly_rate: monthly
        }
      end

      def sanitize!(attr)
        attr.each do |key, value|
          attr[key] = nil if   value == "null"
          attr[key] = false if value == "false"
          attr[key] = true if  value == "true"
        end
        attr[:city] = nil unless ~ /([A-Z])\w+/
        attr
      end

      def owner_info(data)
        {
          owner_name:         data.get("host.name"),
          owner_phone_number: data.get("host.phone"),
          owner_email:        data.get("host.email")
        }
      end

      # See PROPERTY_TYPE_MAPPINGS for supported bnbhero subtype
      def type_and_subtype(data)
        PROPERTY_TYPE_MAPPINGS[data["type"]] || {}
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
