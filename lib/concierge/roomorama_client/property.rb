class Concierge::RoomoramaClient

  # +Concierge::RoomoramaClient::Property+
  #
  # This class is responsible for wrapping the properties of an entry in the `rooms`
  # table in Roomorama. It includes attribute accessors for all parameters accepted
  # by Roomorama's API, as well as convenience methods to set property images
  # and update the availabilities calendar.
  #
  # Usage
  #
  #   property = Concierge::RoomoramaClient::Property.new("ID123")
  #   property.title = "Beautiful Apartment"
  #   property.multi_unit!
  #
  #   image = Concierge::RoomoramaClient::Image.new("img134")
  #   image.url = "https://www.example.org/image.png"
  #   property.add_image(image)
  #
  #   property.update_calendar("2016-05-22" => true, "2016-05-23" => true")
  class Property
    attr_accessor :type, :title, :address, :postal_code, :city, :description,
      :number_of_bedrooms, :max_guests, :minimum_stay, :nightly_rate,
      :weekly_rate, :monthly_rate, :default_to_available, :availabilities,
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
      :services_concierge_rate, :disabled, :instant_booking

    # identifier - the identifier on the supplier system. Required attribute
    def initialize(identifier)
      @identifier = identifier
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
      image.validate!
      images << image
    end

    def add_unit(unit)
      unit.validate!

      multi_unit!
      units << unit
    end

    def update_calendar(dates)
      calendar.merge!(dates.dup)
    end

    def images
      @images ||= []
    end

    def calendar
      @calendar ||= {}
    end

    def units
      @units ||= []
    end
  end

end
