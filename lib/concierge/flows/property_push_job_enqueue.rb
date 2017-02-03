module Concierge::Flows
  # +Concierge::Flows::PropertyPushJobEnqueue+
  #
  # This is used when a manual push is required from
  # concierge to roomorama; for example, a reset of
  # property data on roomorama is needed, but we do not
  # want to fetch properties from suppliers again.
  class PropertyPushJobEnqueue
    attr_reader :element

    def initialize(ids)
      @element = Concierge::Queue::Element.new(
        operation: "properties_push",
        data:      { ids: [ids] }
      )
    end

    def call
      queue.add(element)
    end

    def queue
      @queue ||= begin
        credentials = Concierge::Credentials.for("sqs")
        Concierge::Queue.new(credentials)
      end
    end
  end
end

