module Concierge

  # +Concierge::Context+
  #
  # This class holds the collection of events that were registered over the
  # lifecycle of a request.
  #
  # Usage:
  #
  #   context = Concierge::Context.new
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
  class Context
    attr_reader :data, :events

    def initialize(type:)
      @data   = initial_data(type)
      @events = []
    end

    # event - and event. Typically, a class under +Concierge::Context+.
    #
    # The +event+ object is expected to respond to the +to_h+ method, producing
    # a hash with a +type+ field. This field is later mapped to one of
    # the event presenters. Therefore, the value of that field must be
    # among the types for which there is a corresponding presenter.
    def augment(event)
      events << event
    end

    def to_h
      data.merge(events: events.map(&:to_h))
    end

    private

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
