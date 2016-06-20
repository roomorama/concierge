module SAW
  module Entities
    class DetailedProperty
      attr_reader :internal_id, :type, :title, :description, :lat, :lon, :city,
                  :neighborhood, :address, :country, :amenities, 
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
        @not_supported_amenities = attrs[:not_supported_amenities]
        @multi_unit              = attrs[:multi_unit]
      end

      def multi_unit?
        !!@multi_unit
      end
    end
  end
end
