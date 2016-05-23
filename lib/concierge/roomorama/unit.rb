module Roomorama

  # +Roomorama::Unit+
  #
  # This class is responsible for wrapping the units of an entry in the `units`
  # table in Roomorama. It includes attribute accessors for all parameters accepted
  # by Roomorama's API, as well as convenience methods to set unit images
  # and update the availabilities calendar.
  #
  # Usage
  #
  #   unit = Roomorama::Unit.new("ID123Unit")
  #   unit.title = "Beautiful Apartment"
  #
  #   image = Roomorama::Image.new("img134")
  #   image.url = "https://www.example.org/image.png"
  #   unit.add_image(image)
  #
  #   unit.update_calendar("2016-05-22" => true, "2016-05-23" => true")
  class Unit

    # +Roomorama::Unit::ValidationError+
    #
    # Raised when a unit fails to meet the expected requirements in terms of
    # parameter presence.
    class ValidationError < Roomorama::Error
      def initialize(message)
        super("Unit validation failed: #{message}")
      end
    end

    attr_accessor :title, :description, :nightly_rate, :weekly_rate, :monthly_rate,
      :number_of_bedrooms, :number_of_units, :identifier, :number_of_bathrooms,
      :floor, :number_of_double_beds, :number_of_single_beds, :number_of_sofa_beds,
      :surface, :surface_unit, :amenities, :max_guests, :minimum_stay, :smoking_allowed,
      :pets_allowed, :tax_rate, :extra_guest_surcharge, :disabled

    # identifier - the identifier on the supplier system. Required attribute
    def initialize(identifier)
      @identifier = identifier
    end

    # validates that all required fields for a unit are present. A unit needs:
    #
    # * a non-empty identifier
    # * a list of images
    # * a set of availabilities.
    #
    # If any of the validations above fail, this method will raise a
    # +Roomorama::Unit::ValidationError+ exception. If all
    # required parameters are present, +true+ is returned.
    def validate!
      if identifier.to_s.empty?
        raise ValidationError.new("identifier is not given or empty")
      elsif images.empty?
        raise ValidationError.new("no images")
      elsif calendar.empty?
        raise ValidationError.new("no availabilities")
      else
        true
      end
    end

    def add_image(image)
      image.validate!
      images << image
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
  end

end
