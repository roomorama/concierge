module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Property+
    #
    # This class is responsible for building a
    # +RentalsUnited::Entities::Property+ object from a hash which was fetched
    # from the RentalsUnited API.
    class Property
      attr_reader :property_hash

      EN_DESCRIPTION_LANG_CODE = "1"

      # Initialize +RentalsUnited::Mappers::Property+
      #
      # Arguments:
      #
      #   * +property_hash+ [Concierge::SafeAccessHash] property hash object
      def initialize(property_hash)
        @property_hash = property_hash
      end

      # Builds a property_hash
      #
      # Returns [RentalsUnited::Entities::Property]
      def build_property
        property = Roomorama::Property.new(property_hash.get("ID"))
        property.title = property_hash.get("Name")
        property.description = en_description(property_hash)
        property.lat   = property_hash.get("Coordinates.Latitude").to_f
        property.lng   = property_hash.get("Coordinates.Longitude").to_f
        property.address = property_hash.get("Street")
        property.postal_code = property_hash.get("ZipCode")

        property_type = find_property_type(property_hash.get("ObjectTypeID"))

        if property_type
          property.type = property_type.roomorama_name
          property.subtype = property_type.roomorama_subtype_name
        end

        set_images!(property)

        property
      end

      private
      def set_images!(property); end

      def find_property_type(id)
        RentalsUnited::Dictionaries::PropertyTypes.find(id)
      end

      def en_description(hash)
        descriptions = hash.get("Descriptions.Description")
        en_description = Array(descriptions).find do |desc|
          desc["@LanguageID"] == EN_DESCRIPTION_LANG_CODE
        end

        en_description["Text"]
      end
    end
  end
end
