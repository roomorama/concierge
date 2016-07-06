module Support
  module SAW
    module LastContextEvent
      def last_context_event
        Concierge.context.events.last.to_h
      end
    end
  end
end
