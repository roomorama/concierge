class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::Diff+
  #
  # This class is responsible for encapsulating the operation of applying a
  # +diff+ to a property, using Roomorama's API. It receives a
  # +Roomorama::Diff+ parameter as input and generates an operation that
  # can be used with +Roomorama::Client+ to apply a set of changes to
  # a property.
  #
  # Usage
  #
  #   diff      = Romorama::Diff.new("property_identifier")
  #   operation = Roomorama::Client::Operations::diff.new(diff)
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
