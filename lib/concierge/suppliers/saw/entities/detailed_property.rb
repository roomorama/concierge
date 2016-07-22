module SAW
  module Entities
    # +SAW::Entities::DetailedProperty+
    #
    # This entity corresponds to a detailed property that was fetched from the
    # SAW API.
    #
    # +SAW::Entities::DetailedProperty+ is different from
    # +SAW::Entities::BasicProperty+: some of property attributes are different
    #
    # Attributes
    #
    # +internal_id+             - the ID of the property in SAW database
    # +type+                    - room type
    # +title+                   - the short title of the property
    # +description+             - the description of the property
    # +lon+                     - address longitude
    # +lat+                     - address latitude
    # +city+                    - city in which property located in
    # +neighborhood+            - city neighborhood (region) in which property
    #                             located in
    # +address+                 - property address
    # +country+                 - country
    # +amenities+               - supported amenities
    # +images+                  - supported images (photos)
    # +bed_configurations+      - supported bed types configurations
    # +property_accommodations+ - supported property accommodations
    # +not_supported_amenities+ - list of not supported amenitites
    # +multi_unit+              - boolean flag indicating that property is
    #                             multi unit
    class DetailedProperty
      attr_reader :internal_id, :type, :title, :description, :lat, :lon, :city,
                  :neighborhood, :address, :country, :amenities,
                  :bed_configurations, :property_accommodations,
                  :not_supported_amenities

      def initialize(attrs = {})
        @internal_id             = attrs[:internal_id]
        @type                    = attrs[:type]
        @title                   = attrs[:title]
        @description             = attrs[:description]
        @lon                     = attrs[:lon]
        @lat                     = attrs[:lat]
        @city                    = attrs[:city]
        @neighborhood            = attrs[:neighborhood]
        @address                 = attrs[:address]
        @country                 = attrs[:country]
        @amenities               = attrs[:amenities]
        @images                  = attrs[:images]
        @bed_configurations      = attrs[:bed_configurations]
        @property_accommodations = attrs[:property_accommodations]
        @not_supported_amenities = attrs[:not_supported_amenities]
        @multi_unit              = attrs[:multi_unit]
      end

      def multi_unit?
        !!@multi_unit
      end

      def images
        Array(@images)
      end

      def images=(images)
        @images = images
      end
    end
  end
end
