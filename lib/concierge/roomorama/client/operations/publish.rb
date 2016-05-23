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
  class Publish

      # the Roomorama API endpoint for the +publish+ call
    ENDPOINT = "/v1.0/host/publish"

    attr_reader :property

    # property - a +Roomorama::Client::Operations::Property+ object
    #
    # On initialization the +validate!+ method of the property is called - therefore,
    # an operation cannot be built unless the property given is conformant to the
    # basica validations performed on that class.
    def initialize(property)
      @property = property
      property.validate!
    end

    def endpoint
      ENDPOINT
    end

    def request_method
      :post
    end

    def request_data
      property.to_h
    end

  end
end
