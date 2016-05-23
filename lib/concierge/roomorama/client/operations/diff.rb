class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::Publish+
  #
  # This class is responsible for encapsulating the logic of serializing a property's
  # attributes in a format that is understandable by the publish call of Roomorama's
  # API. Following the protocol expected by the API client, this operation specifies:
  #
  # * the HTTP method of the API call to be performed (POST)
  # * the endpoint of the API call
  # * the request body of a valid call to that endpoint.
  #
  # Usage
  #
  #   operation = Roomorama::Client::Operations::Publish.new(property)
  #   roomorama_client.perform(operation)
  class Diff

    # the Roomorama API endpoint for the +apply+ call
    ENDPOINT = "/v1.0/host/apply"

    attr_reader :property_diff

    # diff - a +Roomorama::Diff+ object
    #
    # On initialization the +validate!+ method of the diff is called - therefore,
    # an operation cannot be built unless the property given is conformant to the
    # basica validations performed on that class.
    def initialize(diff)
      @property_diff = diff
      property_diff.validate!
    end

    def endpoint
      ENDPOINT
    end

    def request_method
      :put
    end

    def request_data
      property_diff.to_h
    end

  end
end
