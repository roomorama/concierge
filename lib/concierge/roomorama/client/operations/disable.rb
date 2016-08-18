class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::Disable
  #
  # This is represents the operation of disabling a property managed by a
  # supplier on Roomorama. The events on which this can occur include:
  #
  # * the host disabled the property on the supplier system;
  # * the payment terms of the property are no longer compatible with Roomorama.
  #
  # This relies on the +disable+ endpoint of the +publish+ API, which allows
  # a property to be removed through its identifier.
  class Disable

    # the Roomorama API endpoint for the +disable+ call by supplier identifier.
    ENDPOINT = "/v1.0/host/disable"

    attr_reader :identifiers

    # collection - a collection of property identifiers
    def initialize(collection)
      @identifiers = collection
    end

    def endpoint
      ENDPOINT
    end

    def request_method
      :delete
    end

    def request_data
      { identifiers: identifiers }
    end

  end
end
