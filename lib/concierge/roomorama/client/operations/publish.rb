class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::Publish+
  #
  # This class is responsible for encapsulating the operation of publishing a
  # new property in Roomorama, using its +publish+ API.
  #
  # Usage
  #
  #   property  = Roomorama::Property.new("identifier")
  #   operation = Roomorama::Client::Operations::Publish.new(property)
  #   roomorama_client.perform(operation)
  class Publish

    # the Roomorama API endpoint for the +publish+ call
    ENDPOINT = "/v1.0/host/publish"

    attr_reader :property

    # property - a +Roomorama::Property+ object
    #
    # On initialization the +validate!+ method of the property is called - therefore,
    # an operation cannot be built unless the property given is conformant to the
    # basic validations performed on that class.
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
