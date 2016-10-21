require_relative "mappers"
require_relative "property"
require_relative "unit"
require_relative "translated"

module Roomorama

  class Diff

    # +Roomorama::Diff::ValidationError+
    #
    # Raised when a property diff fails to meet expected parameter requirements.
    class ValidationError < Roomorama::Error
      def initialize(message)
        super("Diff validation error: #{message}")
      end
    end

    attr_accessor *Roomorama::Property::ATTRIBUTES

    include Roomorama::Translated
    include Roomorama::Mappers

    ChangeSet = Struct.new(:created, :updated, :deleted)

    attr_reader :image_changes, :unit_changes, :erased

    # identifier - the identifier on the supplier system. Required attribute
    def initialize(identifier)
      @identifier    = identifier
      @image_changes = ChangeSet.new([], [], [])
      @unit_changes  = ChangeSet.new([], [], [])
      @erased        = []
    end

    # allows setting attributes to the diff using a Hash-like syntax.
    def []=(attr, value)
      if Roomorama::Property::ATTRIBUTES.include?(attr)
        setter = [attr, "="].join
        public_send(setter, value)
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
      image_changes.created << image
    end

    def change_image(image_diff)
      image_changes.updated << image_diff
    end

    def delete_image(identifier)
      image_changes.deleted << identifier
    end

    def add_unit(unit)
      @multi_unit = true
      unit_changes.created << unit
    end

    def change_unit(unit_diff)
      unit_changes.updated << unit_diff
    end

    def delete_unit(identifier)
      unit_changes.deleted << identifier
    end

    # makes sure that a non-empty property identifier is passed.
    def validate!
      if identifier.to_s.empty?
        raise ValidationError.new("identifier is required")
      else
        [image_changes.created,
         image_changes.updated,
         unit_changes.created,
         unit_changes.updated].each do |collection|
          collection.each(&:validate!)
        end

        true
      end
    end

    # checks whether or not any changes were applied to this diff instance.
    #
    # diff = Roomorama::Diff.new("propertyID")
    # diff.empty? # => true
    #
    # diff.title = "New Title"
    # diff.empty? # => false
    def empty?
      to_h.tap { |changes| changes.delete(:identifier) }.empty?
    end

    def to_h
      data = {
        identifier:                     identifier,
        type:                           type,
        subtype:                        subtype,
        title:                          title,
        description:                    description,
        description_append:             description_append,
        translations:                   translations,
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
        multi_unit:                     multi_unit,
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
        disabled:                       disabled,
        instant_booking:                instant_booking
      }

      mapped_image_changes = map_changes(image_changes)
      unless mapped_image_changes.empty?
        data[:images] = mapped_image_changes
      end

      mapped_unit_changes = map_changes(unit_changes)
      unless mapped_unit_changes.empty?
        data[:units] = mapped_unit_changes
      end

      scrub(data, erased)
    end
  end

end
