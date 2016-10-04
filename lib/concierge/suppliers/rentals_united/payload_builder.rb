require 'tilt'

module RentalsUnited
  # +RentalsUnited::PayloadBuilder+
  #
  # This class builds XML payloads for all RentalsUnited endpoints.
  class PayloadBuilder
    TEMPLATES_PATH = "lib/concierge/suppliers/rentals_united/templates"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def build_properties_collection_fetch_payload(owner_id)
      template_locals = {
        credentials: credentials,
        owner_id: owner_id
      }
      render(:properties_collection_fetch, template_locals)
    end

    def build_locations_fetch_payload
      template_locals = { credentials: credentials }
      render(:locations_fetch, template_locals)
    end

    def build_location_currencies_fetch_payload
      template_locals = { credentials: credentials }
      render(:location_currencies_fetch, template_locals)
    end

    def build_property_fetch_payload(property_id)
      template_locals = {
        credentials: credentials,
        property_id: property_id
      }
      render(:property_fetch, template_locals)
    end

    def build_owner_fetch_payload(owner_id)
      template_locals = {
        credentials: credentials,
        owner_id: owner_id
      }
      render(:owner_fetch, template_locals)
    end

    def build_availabilities_fetch_payload(property_id, date_from, date_to)
      template_locals = {
        credentials: credentials,
        property_id: property_id,
        date_from: date_from,
        date_to: date_to
      }
      render(:availabilities_fetch, template_locals)
    end

    def build_seasons_fetch_payload(property_id, date_from, date_to)
      template_locals = {
        credentials: credentials,
        property_id: property_id,
        date_from: date_from,
        date_to: date_to
      }
      render(:seasons_fetch, template_locals)
    end

    def build_price_fetch_payload(property_id:, check_in:, check_out:, num_guests:)
      template_locals = {
        credentials: credentials,
        property_id: property_id,
        check_in:    check_in,
        check_out:   check_out,
        num_guests:  num_guests
      }
      render(:price_fetch, template_locals)
    end

    def build_booking_payload(property_id:, check_in:, check_out:, num_guests:, total:, user:)
      template_locals = {
        credentials: credentials,
        property_id: property_id,
        num_guests:  num_guests,
        check_in:    check_in,
        check_out:   check_out,
        total:       total,
        first_name:  user.fetch(:first_name),
        last_name:   user.fetch(:last_name),
        email:       user.fetch(:email),
        phone:       user.fetch(:phone),
        address:     user.fetch(:address),
        postal_code: user.fetch(:postal_code)
      }
      render(:booking, template_locals)
    end

    private
    def render(template_name, local_vars)
      path = Hanami.root.join(TEMPLATES_PATH, "#{template_name}.xml.erb")
      Tilt.new(path).render(Object.new, local_vars)
    end
  end
end
