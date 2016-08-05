module Ciirus
  module Mappers
    # +Ciirus::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    # from data getting from Ciirus API.
    class RoomoramaProperty
      # Maps Ciirus PropertyType to Roomorama property type/subtype
      PROPERTY_TYPES = Concierge::SafeAccessHash.new({
        'Condo'           => {type: 'apartment', subtype: 'condo'},
        'Townhouse'       => {type: 'house', subtype: 'townhouse'},
        'Apartment'       => {type: 'apartment', subtype: 'apartment'},
        'Villa'           => {type: 'house', subtype: 'villa'},
        'Signature Villa' => {type: 'house', subtype: 'villa'},
        'House'           => {type: 'house', subtype: 'house'},
        'Cottage'         => {type: 'house', subtype: 'cottage'},
        'B+B'             => {type: 'bnb'},
        'Cabin'           => {type: 'house', subtype: 'cabin'},
        'Hotel'           => {type: 'others', subtype: 'room'},
        'Motel'           => {type: 'others', subtype: 'room'},
        'Office'          => {type: 'others', subtype: 'office'},
        'Studio'          => {type: 'apartment', subtype: 'studio/bachelor'},
        'Barn'            => {type: 'others', subtype: 'barn'},
        'Resort'          => {type: 'others', subtype: 'resort'},
        'Resort Home'     => {type: 'house', subtype: 'house'},
        'Private Room'    => {type: 'room'},
        'Finca'           => {type: 'house', subtype: 'house'}
      })


      class << self
        # Maps Ciirus API responses to +Roomorama::Property+
        # Arguments
        #
        #   * +property+ [Ciirus::Entities::Property]
        #   * +images+ [Array] array of images URLs
        #   * +description+ [String]
        #
        # Returns +Roomorama::Property+
        def build(property, images, description)
          result = Roomorama::Property.new(property.property_id)
          result.instant_booking!

          set_base_info!(result, property)
          set_description!(result, description)
          set_images!(result, images)

          result
        end

        private

        def set_base_info!(result, property)
          result.title = property.property_name
          # TODO: handle Unspecified ciirus property type
          result.type = PROPERTY_TYPES.get("#{property.type}.type")
          result.subtype = PROPERTY_TYPES.get("#{property.type}.subtype")
          result.address = property.address
          result.postal_code = property.zip
          result.city = property.city
          result.number_of_bedrooms = property.bedrooms
          result.max_guests = property.sleeps
          result.minimum_stay = property.min_nights_stay
          result.default_to_available = false
          # TODO: convert country to alpha2
          result.country_code = property.country
          result.lat = property.xco
          result.lng = property.yco
          result.number_of_bathrooms = property.bathrooms
          result.number_of_double_beds = calc_double_beds(property)
          result.number_of_single_beds = calc_single_beds(property)
          result.number_of_sofa_beds = calc_sofa_beds(property)
          result.amenities = property.amenities
          result.pets_allowed = property.pets_allowed
          result.currency = property.currency_code
        end

        def set_description!(result, description)
          result.description = description
        end

        def calc_double_beds(property)
          property.king_beds + property.queen_beds + property.full_beds
        end

        def calc_single_beds(property)
          property.twin_beds + (property.extra_bed ? 1 : 0)
        end

        def calc_sofa_beds(property)
          property.sofa_bed ? 1 : 0
        end

        def set_images!(result, images)
          images.each do |url|
            identifier = Digest::MD5.hexdigest(url)
            image = Roomorama::Image.new(identifier)
            image.url = url

            result.add_image(image)
          end
        end
      end
    end
  end
end
