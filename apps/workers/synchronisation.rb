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
  #   sync = Workers::Synchronisation.new(host)
  #
  #   # supplier API is called, raw data is fetched
  #   properties = fetch_properties
  #   properties.each do |attributes|
  #     sync.start(attributes[:identifier]) {
  #       property = Roomorama::Property.new(attributes[:identifier])
  #       # property object is built
  #
  #       Result.new(property)
  #     }
  #   end
  #
  #   sync.finish! # => non-processed properties are deleted at the end of the process.
  class Synchronisation

    attr_reader :host, :router, :processed, :failed

    # host - an instance of +Host+.
    def initialize(host)
      @host      = host
      @router    = Workers::Router.new(host)
      @processed = []
      @failed    = false
    end

    # Indicates that the property with the given +identifier+ is being synchronised.
    #
    # This method wraps all the common logic related to property synchronising. It
    # initializes +Concierge.context+ to an empty context, and collects data about
    # the processing of the identifier given.
    #
    # This method *must* be called with a block which returns a +Result+ instance
    # wrapping a +Roomorama::Property+ object, or a failure, if there were any.
    #
    # Possible scenarios:
    #
    # * the property returned from the block given is valid. It might then be
    #   published or updated, depending on whether or not there were changes
    #   (see +Workers::Router+)
    #
    # * the property returned from the block given fails to meet minimum validations.
    #   In this case, the context is augmented, and an +ExternalError+ is created.
    #
    # * the +Result+ returned by the block given indicates an error while processing
    #   the property. In this case, the external error is also persisted. The caller
    #   is encouraged to have augmented +Concierge.context+ with meaningful information
    #   to aid debugging.
    def start(identifier)
      initialize_context(identifier)
      result = yield(self)

      if result.success?
        property = result.value
        process(property)
      else
        failed!
        announce_failure(result)
        false
      end
    end

    # finishes the synchronisation process. This method should only be called
    # when all properties from the host have already been processed (through
    # the use of +start+). It checks which properties need to be disabled,
    # and enqueues the corresponding job.
    #
    # Note that if one of the properties processed failed (i.e., returned a
    # non-successful +Result+), then this process will not disable all properties
    # on Roomorama (rationale: if a supplier faces an intermittent issue during
    # the synchronisation process, we do not want to disable all properties
    # as a consequence of that.)
    def finish!
      return if failed

      purge = all_identifiers - processed

      unless purge.empty?
        enqueue(disable_op(purge))
      end
    end

    private

    # when a new property is pushed for synchronisation, this class register
    # the identifier of that property so that, when +finish!+ is called,
    # it is able to know which properties should be disabled.
    #
    # It uses +Workers::Router+ to determine which operation should be
    # performed on the property, if any, and enqueues it for execution.
    def push(property)
      processed << property.identifier

      router.dispatch(property).tap do |operation|
        if operation
          enqueue(operation)
        end
      end
    end

    def failed!
      @failed = true
    end

    def initialize_context(identifier)
      Concierge.context = Concierge::Context.new(type: "batch")

      sync_process = Concierge::Context::SyncProcess.new(
        host_id:    host.id,
        identifier: identifier
      )

      Concierge.context.augment(sync_process)
    end

    def process(property)
      property.validate!
      push(property)
      true
    rescue Roomorama::Error => err
      missing_data(err.message, property.to_h)
      announce_failure(Result.error(:missing_data))
      false
    end

    def missing_data(message, attributes)
      missing_data = Concierge::Context::MissingBasicData.new(
        error_message: message,
        attributes:    attributes
      )

      Concierge.context.augment(missing_data)
    end

    def announce_failure(result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   "sync",
        supplier:    SupplierRepository.find(host.supplier_id).name,
        code:        result.error.code,
        message:     "DEPRECATED",
        context:     Concierge.context.to_h,
        happened_at: Time.now,
      })
    end

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
