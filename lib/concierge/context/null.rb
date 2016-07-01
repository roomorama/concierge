class Concierge::Context

  # +Concierge::Context::Null+
  #
  # This is a null object implementing the contract expected by +Concierge::Context+.
  # It responds to the following methods:
  #
  # +events+   - always returns am empty list of events.
  # +augment+  - a no-op, returning +nil+.
  # +enable!+  - no-op
  # +disable!+ - no-op
  # +to_h+     - returns an empty Hash.
  #
  # By default, on applications that do not need context tracking, the context
  # should be set to an instance of this class.
  class Null
    attr_reader :events

    def initialize
      @events = []
    end

    def augment(event)
    end

    def enable!
    end

    def disable!
    end

    def to_h
      {}
    end

  end
end
