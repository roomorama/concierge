module Workers

  # +Workers::Synchronisation+
  #
  # Organizes the synchronisation process for a given host from supplier.
  # It is able to route processed property to the adequate operation
  # (through the use of +Workers::Router+), as well as disabling properties
  # that were published before but are no longer contained in the list
  # of properties for that host.
  #
  # Usage
  #
  #   host = Host.last
  #   sync = +Workers::Synchronisation.new(host)
  #
  #   property = Roomorama::Property.new("id1")
  #   # supplier API is called, property is built
  #   sync.push(property)
  #
  #   sync.finish! # => non-processed properties are deleted at the end of the process.
  class Synchronisation
    attr_reader :host, :router, :processed

    # host - an instance of +Host+.
    def initialize(host)
      @host      = host
      @router    = Workers::Router.new(host)
      @processed = []
    end

    # when a new property is pushed for synchronisation, this class register
    # the identifier of that property so that, when +finish!+ is called,
    # it is able to know which properties should be disabled.
    #
    # It uses +Workers::Router+ to determine which operation should be
    # performed on the property, if any, and enqueues it for execution.
    def push(property)
      processed << property.identifier

      router.dispatch(property).tap do |operation|
        enqueue(operation) if operation
      end
    end

    # finishes the synchronisation process. This method should only be called
    # when all properties from the host have already been +push+ed. It checks which
    # properties need to be disabled, and enqueues the corresponding job.
    def finish!
      purge = all_identifiers - processed

      unless purge.empty?
        enqueue(disable_op(purge))
      end
    end

    private

    def enqueue(operation)
      # next chapter
    end

    def all_identifiers
      PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
    end

    def disable_op(identifiers)
      Roomorama::Client::Operations.disable(identifiers)
    end

  end
end
