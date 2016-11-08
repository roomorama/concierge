module Ciirus
  module Entities
    class Property
      attr_reader :property_id, :property_name, :mc_property_name, :address, :zip, :city, :bedrooms,
                  :sleeps, :type, :country, :xco, :yco, :bathrooms, :king_beds,
                  :queen_beds, :full_beds, :twin_beds, :extra_bed, :sofa_bed,
                  :amenities, :pets_allowed, :currency_code, :main_image_url

      def initialize(attrs = {})
        @property_id      = attrs[:property_id]
        @property_name    = attrs[:property_name]
        @mc_property_name = attrs[:mc_property_name]
        @address          = attrs[:address]
        @zip              = attrs[:zip]
        @city             = attrs[:city]
        @bedrooms         = attrs[:bedrooms]
        @sleeps           = attrs[:sleeps]
        @type             = attrs[:type]
        @country          = attrs[:country]
        @xco              = attrs[:xco]
        @yco              = attrs[:yco]
        @bathrooms        = attrs[:bathrooms]
        @king_beds        = attrs[:king_beds]
        @queen_beds       = attrs[:queen_beds]
        @full_beds        = attrs[:full_beds]
        @twin_beds        = attrs[:twin_beds]
        @extra_bed        = attrs[:extra_bed]
        @sofa_bed         = attrs[:sofa_bed]
        @pets_allowed     = attrs[:pets_allowed]
        @currency_code    = attrs[:currency_code]
        @amenities        = attrs[:amenities]
        @main_image_url   = attrs[:main_image_url]
      end

      def to_json
        h = {
          property_id:      property_id,
          property_name:    property_name,
          mc_property_name: mc_property_name,
          address:          address,
          zip:              zip,
          city:             city,
          bedrooms:         bedrooms,
          sleeps:           sleeps,
          type:             type,
          country:          country,
          xco:              xco,
          yco:              yco,
          bathrooms:        bathrooms,
          king_beds:        king_beds,
          queen_beds:       queen_beds,
          full_beds:        full_beds,
          twin_beds:        twin_beds,
          extra_bed:        extra_bed,
          sofa_bed:         sofa_bed,
          pets_allowed:     pets_allowed,
          currency_code:    currency_code,
          amenities:        amenities,
          main_image_url:   main_image_url
        }
        Yajl::Encoder.encode(h)
      end
    end
  end
end