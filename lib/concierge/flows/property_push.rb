module Concierge::Flows
  # +Concierge::Flows::PropertyPush+
  #
  # This is used when a manual push is required from
  # concierge to roomorama; for example, a reset of
  # property data on roomorama is needed, but we do not
  # want to fetch properties from suppliers again.
  class PropertyPush
    attr_reader :host

    def initialize(host)
      @host = host
    end

    def call
      PropertyRepository.from_host(host).collect do |p|
        publish(p)
      end
    end

    private

    def publish(property)
      roomorama_property_load = load(property)
      return roomorama_property_load unless roomorama_property_load.success?

      op = Roomorama::Client::Operations.publish(roomorama_property_load.value, { should_persist: false })
      Workers::OperationRunner.new(host).perform(op, roomorama_property_load.value)
    end

    def load(property)
      Roomorama::Property.load(property.data)
    end
  end
end

