class Concierge::RoomoramaClient::Operations

  # +Concierge::RoomoramaClient::Operations::Publish+
  #
  # This class is responsible for encapsulating the logic of serializing a property's
  # attributes in a format that is understandable by the publish call of Roomorama's
  # API. Following the protocol expected by the API client, this operation specifies:
  #
  # * the HTTP method of the API call to be performed (POST)
  # * the endpoint of the API call
  # * the request body of a valid call to that endpoint.
  #
  # Usage
  #
  #   operation = Concierge::RoomoramaClient::Operations::Publish.new(property)
  #   roomorama_client.perform(operation)
  class Publish

      # the Roomorama API endpoint for the +publish+ call
    ENDPOINT = "/v1.0/host/publish"

    attr_reader :property

    # property - a +Concierge::RoomoramaClient::Operations::Property+ object
    #
    # On initialization the +validate!+ method of the property is called - therefore,
    # an operation cannot be built unless the property given is conformant to the
    # basica validations performed on that class.
    def initialize(property)
      @property = property
      property.validate!
    end

    def endpoint
      ENDPOINT
    end

    def request_method
      :post
    end

    # check Roomorama's API documentation for information about expected parameters
    # and their format.
    def request_data
      data = {
        identifier:                     property.identifier,
        type:                           property.type,
        subtype:                        property.subtype,
        title:                          property.title,
        description:                    property.description,
        address:                        property.address,
        apartment_number:               property.apartment_number,
        postal_code:                    property.postal_code,
        city:                           property.city,
        neighborhood:                   property.neighborhood,
        country_code:                   property.country_code,
        lat:                            property.lat,
        lng:                            property.lng,
        number_of_bedrooms:             property.number_of_bedrooms,
        number_of_bathrooms:            property.number_of_bathrooms,
        floor:                          property.floor,
        number_of_double_beds:          property.number_of_double_beds,
        number_of_single_beds:          property.number_of_single_beds,
        number_of_sofa_beds:            property.number_of_sofa_beds,
        surface:                        property.surface,
        surface_unit:                   property.surface_unit,
        amenities:                      property.amenities,
        max_guests:                     property.max_guests,
        minimum_stay:                   property.minimum_stay,
        multi_unit:                     property.multi_unit?,
        smoking_allowed:                property.smoking_allowed,
        pets_allowed:                   property.pets_allowed,
        check_in_instructions:          property.check_in_instructions,
        check_in_time:                  property.check_in_time,
        check_out_time:                 property.check_out_time,
        currency:                       property.currency,
        nightly_rate:                   property.nightly_rate,
        weekly_rate:                    property.weekly_rate,
        monthly_rate:                   property.monthly_rate,
        security_deposit_amount:        property.security_deposit_amount,
        security_deposit_type:          property.security_deposit_type,
        security_deposit_currency_code: property.security_deposit_currency_code,
        tax_rate:                       property.tax_rate,
        extra_charges:                  property.extra_charges,
        rate_base_max_guests:           property.rate_base_max_guests,
        extra_guest_surcharge:          property.extra_guest_surcharge,
        default_to_available:           property.default_to_available,
        cancellation_policy:            property.cancellation_policy,
        services_cleaning:              property.services_cleaning,
        services_cleaning_rate:         property.services_cleaning_rate,
        services_cleaning_required:     property.services_cleaning_required,
        services_airport_pickup:        property.services_airport_pickup,
        services_airport_pickup_rate:   property.services_airport_pickup_rate,
        services_car_rental:            property.services_car_rental,
        services_car_rental_rate:       property.services_car_rental_rate,
        services_concierge:             property.services_concierge,
        services_concierge_rate:        property.services_concierge_rate,
        disabled:                       property.disabled,
        instant_booking:                property.instant_booking?
      }

      data[:images]         = map_images(property)
      data[:availabilities] = map_availabilities(property)
      data[:units]          = map_units(property)

      scrub(data)
    end

    private

    def map_images(place)
      place.images.map do |image|
        scrub({
          identifier: image.identifier,
          url:        image.url,
          caption:    image.caption,
          position:   image.position
        })
      end
    end

    def map_availabilities(place)
      sorted_dates = place.calendar.keys.map { |date| Date.parse(date) }.sort
      min_date     = sorted_dates.min
      max_date     = sorted_dates.max

      data = ""
      (min_date..max_date).each do |date|
        availability = place.calendar[date.to_s]

        if availability == true
          data << "1"
        elsif availability == false
          data << "0"
        else
          # if the date is not specified, assume it to be available
          # (real-time checking would involve an API call to the supplier)
          data << "1"
        end
      end

      {
        start_date: min_date.to_s,
        data:       data
      }
    end

    def map_units(property)
      return unless property.multi_unit?

      property.units.map do |unit|
        data = {
          identifier:            unit.identifier,
          title:                 unit.title,
          description:           unit.description,
          nightly_rate:          unit.nightly_rate,
          weekly_rate:           unit.weekly_rate,
          monthly_rate:          unit.monthly_rate,
          number_of_bedrooms:    unit.number_of_bedrooms,
          number_of_units:       unit.number_of_units,
          number_of_bathrooms:   unit.number_of_bathrooms,
          floor:                 unit.floor,
          number_of_double_beds: unit.number_of_double_beds,
          number_of_single_beds: unit.number_of_single_beds,
          number_of_sofa_beds:   unit.number_of_sofa_beds,
          surface:               unit.surface,
          surface_unit:          unit.surface_unit,
          amenities:             unit.amenities,
          max_guests:            unit.max_guests,
          minimum_stay:          unit.minimum_stay,
          smoking_allowed:       unit.smoking_allowed,
          pets_allowed:          unit.pets_allowed,
          tax_rate:              unit.tax_rate,
          extra_guest_surcharge: unit.extra_guest_surcharge,
          disabled:              unit.disabled
        }

        data[:images]         = map_images(unit)
        data[:availabilities] = map_availabilities(unit)

        scrub(data)
      end
    end

    def scrub(data)
      data.delete_if { |_, value| value.to_s.empty? }
    end

  end
end
