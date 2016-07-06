class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::CalendarUpdate+
  #
  # This is represents the operation of update the calendar of a property managed by a
  # supplier on Roomorama.
  #
  class CalendarUpdate

    # the Roomorama API endpoint for the +disable+ call by supplier identifier.
    ENDPOINT = "/v1.0/host/rooms/:id/availabilities".freeze

    attr_reader :property

    # calendar should be a hash that satisfies the /availabilities endpint parameter format
    def initialize(property)
      @property = property
    end

    def endpoint
      ENDPOINT.gsub(":id", roomorama_id_for(identifier))
    end

    def request_method
      :put
    end

    def request_data
      calendar
    end

  end
end
