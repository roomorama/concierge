class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::UpdateCalendar+
  #
  # This class wraps the API call on Roomorama's publish API  to update
  # the calendar in bulk. It receives a +Roomorama::Calendar+ instance
  # as input and generates an operation that can be used by
  # +Roomorama::Client+.
  #
  # Usage
  #
  #   calendar  = Romorama::Calendar.new("property_identifier")
  #   operation = Roomorama::Client::Operations::UpdateCalendar.new(calendar)
  #   roomorama_client.perform(operation)
  class UpdateCalendar

    # the Roomorama API endpoint for the +update_calendar+ call
    ENDPOINT = "/v1.0/host/update_calendar"

    attr_reader :calendar

    # calendar - a +Roomorama::Calendar+ object
    def initialize(calendar)
      @calendar = calendar
    end

    def endpoint
      ENDPOINT
    end

    def request_method
      :put
    end

    def request_data
      calendar.to_h
    end

  end
end
