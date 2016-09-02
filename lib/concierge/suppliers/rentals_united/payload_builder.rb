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

    def build_property_ids_fetch_payload(location_id)
      template_locals = {
        credentials: credentials,
        location_id: location_id
      }
      render(:property_ids_fetch, template_locals)
    end

    def build_cities_fetch_payload
      template_locals = { credentials: credentials }
      render(:cities_fetch, template_locals)
    end

    def build_property_fetch_payload(property_id)
      template_locals = {
        credentials: credentials,
        property_id: property_id
      }
      render(:property_fetch, template_locals)
    end

    private
    def render(template_name, local_vars)
      path = Hanami.root.join(TEMPLATES_PATH, "#{template_name}.xml.erb")
      Tilt.new(path).render(Object.new, local_vars)
    end
  end
end
