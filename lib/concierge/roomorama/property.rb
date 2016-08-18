module Roomorama

  # +Roomorama::Property+
  #
  # This class is responsible for wrapping the properties of an entry in the `rooms`
  # table in Roomorama. It includes attribute accessors for all parameters accepted
  # by Roomorama's API, as well as convenience methods to set property images.
  #
  # Usage
  #
  #   property = Roomorama::Property.new("ID123")
  #   property.title = "Beautiful Apartment"
  #   property.multi_unit!
  #
  #   image = Roomorama::Image.new("img134")
  #   image.url = "https://www.example.org/image.png"
  #   property.add_image(image)
  class Property
    include Roomorama::Mappers

    # +Roomorama::Property::ValidationError+
    #
    # Raised when a property fails to meet expected parameter requirements.
    class ValidationError < Roomorama::Error
      def initialize(message)
        super("Property validation error: #{message}")
      end
    end

    # creates a +Roomorama::Property+ instance from a Hash of +attributes+ given.
    # This method returns a +Result+ instance wrapping the corresponding instance
    # of +Roomorama::Property+ when successful. In case there are validation errors
    # (lack of identifiers, mostly), this method will return an unsuccessful +Result+
    # instance.
    def self.load(attributes)
      instance = new(attributes[:identifier])

      ATTRIBUTES.each do |attr|
        unless attributes[attr].nil?
          instance[attr] = attributes[attr]
        end
      end

      Array(attributes[:images]).each do |image|
        data = Concierge::SafeAccessHash.new(image)
        instance.add_image(Roomorama::Image.load(data))
      end

      Array(attributes[:units]).each do |unit|
        data = Concierge::SafeAccessHash.new(unit)
        instance.add_unit(Roomorama::Unit.load(data))
      end

      instance.validate!
      Result.new(instance)
    rescue Roomorama::Error => err
      data = {
        error:      err.message,
        attributes: attributes.to_h
      }

      Result.error(:missing_required_data, data)
    end

    ATTRIBUTES = [:type, :title, :address, :postal_code, :city, :description,
      :number_of_bedrooms, :max_guests, :minimum_stay, :nightly_rate,
      :weekly_rate, :monthly_rate, :default_to_available,
      :identifier, :subtype, :apartment_number, :neighborhood, :country_code,
      :lat, :lng, :number_of_bathrooms, :floor, :number_of_double_beds,
      :number_of_single_beds, :number_of_sofa_beds, :surface, :surface_unit,
      :amenities, :multi_unit, :smoking_allowed, :pets_allowed, :check_in_instructions,
      :check_in_time, :check_out_time, :currency, :security_deposit_amount,
      :security_deposit_type, :security_deposit_currency_code, :tax_rate,
      :extra_charges, :rate_base_max_guests, :extra_guest_surcharge,
      :cancellation_policy, :services_cleaning, :services_cleaning_rate,
      :services_cleaning_required, :services_airport_pickup, :services_car_rental,
      :services_car_rental_rate, :services_airport_pickup_rate, :services_concierge,
      :services_concierge_rate, :disabled, :instant_booking, :owner_name,
      :owner_email, :owner_phone_number, :owner_city]

    attr_accessor *ATTRIBUTES

    # identifier - the identifier on the supplier system. Required attribute
    def initialize(identifier)
      @identifier = identifier
    end

    def []=(name, value)
      if ATTRIBUTES.include?(name)
        setter = [name, "="].join
        public_send(setter, value)
      end
    end

    def multi_unit!
      @multi_unit = true
    end

    def multi_unit?
      !!@multi_unit
    end

    def instant_booking!
      @instant_booking = true
    end

    def instant_booking?
      !!@instant_booking
    end

    def add_image(image)
      images << image
    end

    def drop_images!
      @images = []
    end

    def add_unit(unit)
      multi_unit!
      units << unit
    end

    # validates that all required fields for a unit are present. A unit needs:
    #
    # * a non-empty identifier
    # * a list of images
    #
    # Note that the validations performed here are basic validations performed in
    # order to avoid making API calls to Roomorama when it is possible to know in
    # advance that there will be failures due to missing data. However, the goal
    # here is not to entirely duplicate all validations present on Roomorama -
    # that would bring forth a duplication of validation rules that should be
    # avoided.
    #
    # If any of the validations above fail, this method will raise a
    # +Roomorama::Property::ValidationError+ exception. If all
    # required parameters are present, +true+ is returned.
    def validate!
      if identifier.to_s.empty?
        raise ValidationError.new("identifier is not given or empty")
      elsif disabled
        # if there's an id and it's disabled, it's already a valid property
        true
      elsif images.empty?
        raise ValidationError.new("no images")
      else
        images.each(&:validate!)
        units.each(&:validate!)

        true
      end
    end

    def images
      @images ||= []
    end

    def units
      @units ||= []
    end

    # check Roomorama's API documentation for information about expected parameters
    # and their format.
    def to_h
      data = {
        identifier:                     identifier,
        type:                           type,
        subtype:                        subtype,
        title:                          title,
        description:                    description,
        address:                        address,
        apartment_number:               apartment_number,
        postal_code:                    postal_code,
        city:                           city,
        neighborhood:                   neighborhood,
        country_code:                   country_code,
        lat:                            lat,
        lng:                            lng,
        number_of_bedrooms:             number_of_bedrooms,
        number_of_bathrooms:            number_of_bathrooms,
        floor:                          floor,
        number_of_double_beds:          number_of_double_beds,
        number_of_single_beds:          number_of_single_beds,
        number_of_sofa_beds:            number_of_sofa_beds,
        surface:                        surface,
        surface_unit:                   surface_unit,
        amenities:                      Array(amenities).join(","),
        max_guests:                     max_guests,
        minimum_stay:                   minimum_stay,
        multi_unit:                     multi_unit?,
        smoking_allowed:                smoking_allowed,
        pets_allowed:                   pets_allowed,
        check_in_instructions:          check_in_instructions,
        check_in_time:                  check_in_time,
        check_out_time:                 check_out_time,
        currency:                       currency,
        nightly_rate:                   nightly_rate,
        weekly_rate:                    weekly_rate,
        monthly_rate:                   monthly_rate,
        security_deposit_amount:        security_deposit_amount,
        security_deposit_type:          security_deposit_type,
        security_deposit_currency_code: security_deposit_currency_code,
        tax_rate:                       tax_rate,
        extra_charges:                  extra_charges,
        rate_base_max_guests:           rate_base_max_guests,
        extra_guest_surcharge:          extra_guest_surcharge,
        default_to_available:           default_to_available,
        cancellation_policy:            cancellation_policy,
        services_cleaning:              services_cleaning,
        services_cleaning_rate:         services_cleaning_rate,
        services_cleaning_required:     services_cleaning_required,
        services_airport_pickup:        services_airport_pickup,
        services_airport_pickup_rate:   services_airport_pickup_rate,
        services_car_rental:            services_car_rental,
        services_car_rental_rate:       services_car_rental_rate,
        services_concierge:             services_concierge,
        services_concierge_rate:        services_concierge_rate,
        owner_name:                     owner_name,
        owner_email:                    owner_email,
        owner_phone_number:             owner_phone_number,
        owner_city:                     owner_city,
        disabled:                       disabled,
        instant_booking:                instant_booking?
      }

      data[:images]         = map_images(self)
      data[:units]          = map_units(self)

      scrub(data)
    end

    private

    def map_units(property)
      return unless property.multi_unit?
      property.units.map(&:to_h)
    end
  end

end
