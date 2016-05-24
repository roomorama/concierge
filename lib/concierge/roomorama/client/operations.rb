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

  end

end
