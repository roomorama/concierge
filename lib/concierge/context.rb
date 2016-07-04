module Concierge

  # +Concierge::Context+
  #
  # This class holds the collection of events that were registered over the
  # lifecycle of a request.
  #
  # Usage:
  #
  #   context = Concierge::Context.new(type: "batch")
  #   request = Concierge::Context::NetworkRequest.new(...)
  #   context.augment(request)
  #   failure = Concierge::Context::NetworkFailure.new(...)
  #   context.augment(failure)
  #
  #   context.to_h # => { ... } serializable hash
  #
  # This class starts off as an empty container, and can then be *augmented*
  # in order to provide more information of the context of a running request.
  # Therefore, in case there is some error while processing the request,
  # the context can be serialized (via +to_h+) and it will include all relevant
  # information of the main events that happened on that request.
  #
  # Context tracking can also be disabled and re-enabled again if it is desired
  # to stop context tracking for some calculation (example - a network call to fetch
  # a large file, where it is not desired to keep the entire network response in the
  # context.) Examples of such use case:
  #
  #   context = Concierge::Context.new(type: "batch")
  #   context.agument(event)
  #
  #   # network call to fetch large file
  #   context.disable!
  #   perform_call
  #
  #   # later, if context is to be tracked again
  #   context.enable!
  class Context

    # +Concierge::Context::EventsTracker+
    #
    # This class plays the role of keeping track of events added to the transaction
    # context on Concierge. This implementation is the one used when context tracking
    # is enabled, and events tracked are added to an internal data structure for
    # later serialization.
    class EventsTracker
      attr_reader :events

      def initialize(events)
        @events = events
      end

      def track(event)
        @events << event
      end
    end

    # +Concierge::Context::NullTracker+
    #
    # This is an implementation of the null object pattern for event tracking
    # on Concierge. Whenever context tracking is disabled, the event tracking
    # role is played by an instance of this class, which receives the collection
    # of currently tracked events, and ignore any further calls to +track+.
    class NullTracker
      attr_reader :events

      def initialize(events)
        @events = events
      end

      def track(event)
        # no-op
      end
    end

    attr_reader :data, :events_tracker

    # type           - the type of transaction being carried out.
    # events_tracker - the instance to play the event-tracking role.
    #
    # The +events_tracker+ argument is expected to conform to a simple protocol:
    #
    #   * track(event) - tracks the event given
    #   * events()     - returns a list of tracked events.
    def initialize(type:, events_tracker: default_events_tracker)
      @data           = initial_data(type)
      @events_tracker = events_tracker
    end

    # event - and event. Typically, a class under +Concierge::Context+.
    #
    # The +event+ object is expected to respond to the +to_h+ method, producing
    # a hash with a +type+ field. This field is later mapped to one of
    # the event presenters. Therefore, the value of that field must be
    # among the types for which there is a corresponding presenter.
    def augment(event)
      events_tracker.track(event)
    end

    # the list of events tracked by this context instance.
    def events
      events_tracker.events
    end

    # enables context tracking, switching the context tracking role to an instance
    # of +Concierge::Context::EventsTracker+. The list of events received is the collection
    # of currently tracked events.
    #
    # Has no effect if context tracking is already enabled.
    def enable!
      @events_tracker = EventsTracker.new(events)
    end

    # disables context tracking, switching the context tracking role to an instance
    # of +Concierge::Context::NullTracker+.
    #
    # Has no effect if context tracking is already disabled.
    def disable!
      @events_tracker = NullTracker.new(events)
    end

    def to_h
      data.merge(events: events.map(&:to_h))
    end

    private

    def default_events_tracker
      EventsTracker.new([])
    end

    # adds initial metadata on the payload. Stores the running version
    # of Concierge, the server handling the request, as well as the
    # type of request being processed (API - default - or batch processing.)
    def initial_data(type)
      {
        version: Concierge::VERSION,
        host:    Socket.gethostname,
        type:    type
      }
    end

  end
end
