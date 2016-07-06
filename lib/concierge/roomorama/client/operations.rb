class Roomorama::Client

  # +Roomorama::Client::Operations+
  #
  # Provides a set of shortcut methods for performing operations on the
  # Roomorama API.
  class Operations

    # Performs a +publish+ operation for the given property.
    def self.publish(property)
      Publish.new(property)
    end

    # Performs a +diff+ operation for the given property diff.
    def self.diff(property_diff)
      Diff.new(property_diff)
    end

    # Performs a +disable+ operation, removing the property with the given
    # identifiers on Roomorama.
    def self.disable(identifiers)
      Disable.new(identifiers)
    end

    # Performs a +update_calendar+ operation, updating the calendar of the
    # property with the given Roomorama property.
    def self.calendar_update(property)
      CalendarUpdate.new(property)
    end

  end

end
