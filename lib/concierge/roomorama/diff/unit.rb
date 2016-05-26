require_relative "../mappers"

class Roomorama::Diff

  # +Roomorama::Diff::Unit+
  #
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

    include Roomorama::Mappers

    ChangeSet = Struct.new(:created, :updated, :deleted)

    attr_reader :image_changes, :erased

    # identifier - the identifier on the supplier system. Required attribute
    def initialize(identifier)
      @identifier    = identifier
      @image_changes = ChangeSet.new([], [], [])
      @erased        = []
    end

    # A unit diff needs a valid identifier.
    def validate!
      if identifier.to_s.empty?
        raise ValidationError.new("identifier is not given or empty")
      else
        true
      end
    end

    # allows the caller to specify that a given attribute was erased in the diff.
    # By default, the +scrub+ method removes all +nil+ entries from the resulting
    # Hash when +to_h+ is invoked. However, if +erase+ was called for a specific
    # attribute, that attribute will be set to +nil+ when +to_h+ is called.
    def erase(attr)
      erased << attr.to_s
    end

    def add_image(image)
      image.validate!
      image_changes.created << image
    end

    def change_image(image_diff)
      image_diff.validate!
      image_changes.updated << image_diff
    end

    def delete_image(identifier)
      image_changes.deleted << identifier
    end

    def update_calendar(dates)
      calendar.merge!(dates.dup)
    end

    def calendar
      @calendar ||= {}
    end

    def to_h
      # map unit attribute changes
      data = {
        identifier:            identifier,
        title:                 title,
        description:           description,
        nightly_rate:          nightly_rate,
        weekly_rate:           weekly_rate,
        monthly_rate:          monthly_rate,
        number_of_bedrooms:    number_of_bedrooms,
        number_of_units:       number_of_units,
        number_of_bathrooms:   number_of_bathrooms,
        floor:                 floor,
        number_of_double_beds: number_of_double_beds,
        number_of_single_beds: number_of_single_beds,
        number_of_sofa_beds:   number_of_sofa_beds,
        surface:               surface,
        surface_unit:          surface_unit,
        amenities:             amenities,
        max_guests:            max_guests,
        minimum_stay:          minimum_stay,
        smoking_allowed:       smoking_allowed,
        pets_allowed:          pets_allowed,
        tax_rate:              tax_rate,
        extra_guest_surcharge: extra_guest_surcharge,
        disabled:              disabled
      }

      # map created/updated/deleted images
      mapped_image_changes  = map_changes(image_changes)

      # only include an images field if there are changes to be applied.
      unless mapped_image_changes.empty?
        data[:images] = mapped_image_changes
      end

      # no need for the +availabilities+ field if there is no calendar changes.
      unless calendar.empty?
        data[:availabilities] = map_availabilities(self)
      end

      scrub(data, erased)
    end
  end

end
