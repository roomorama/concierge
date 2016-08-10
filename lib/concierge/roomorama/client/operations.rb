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

    # Performs an +update_calendar+ operation, making changes in bulk to
    # a property's availabilities calendar.
    def self.update_calendar(calendar)
      UpdateCalendar.new(calendar)
    end

    def self.create_host(identifier)
      CreateHost.new(identifier)
    end

  end

end
