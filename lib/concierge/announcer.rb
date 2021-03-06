module Concierge

  # +Concierge::Announcer+
  #
  # This class implements a simple publish/subscribe facility for Concierge.
  # Listeners are associated to events which are fired when the event is triggered,
  # in order of subscription.
  #
  # Usage
  #
  #   Announcer.on("error") { |error| log.warning(error) }
  #   # ...
  #   Announcer.trigger("error", "something went wrong") # => invokes the block above
  class Announcer

    # Convenience class methods. Delegates all method calls to an instance of this class,
    # in a Singleton implementation.
    class << self
      def _announcer
        @_announcer ||= self.new
      end

      def on(event, &block)
        _announcer.on(event, &block)
      end

      def trigger(event, *args)
        _announcer.trigger(event, *args)
      end
    end

    attr_reader :listeners

    def initialize
      @listeners = Hash.new { |h, k| h[k] = [] }
    end

    # associates a listener to an event.
    #
    # Example
    #
    #   Announcer.on("event") { |call:| logger.info("Received call #{call}") }
    def on(event, &block)
      listeners[event] << block
    end

    # triggers all blocks associated with an event name. Parameters passed
    # to this method are forwarded to the subscribed runnables.
    #
    # Example
    #
    #   Announcer.trigger("event", call: "quote_price")
    def trigger(event, *args)
      listeners[event].map do |listener|
        listener.call(*args)
      end
    end
  end

end
