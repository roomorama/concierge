module Workers

  # +Workers::PropertySynchronisation+
  #
  # Organizes the synchronisation process for a given host from supplier.
  # It is able to route processed property to the adequate operation
  # (through the use of +Workers::Router+), as well as disabling properties
  # that were published before but are no longer contained in the list
  # of properties for that host.
  #
  # Handles exclusively creation/updates of property details. For changes
  # on the availabilities calendar of a property, check the +Workers::CalendarSynchronisation+
  # class.
  #
  # Usage
  #
  #   host = Host.last
  #   sync = Workers::PropertySynchronisation.new(host)
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
  class PropertySynchronisation

    # the kind of background worker that identifies property metadata synchronisation.
    # Calendar availabilities is tackled by +Workers::CalendarSynchronisation+
    WORKER_TYPE = "metadata"

    PropertyCounters = Struct.new(:created, :updated, :deleted)

    attr_reader :host, :router, :sync_record, :counters, :processed, :purge, :skipped_properties

    # host - an instance of +Host+.
    def initialize(host)
      @host               = host
      @router             = Workers::Router.new(host)
      @sync_record        = init_sync_record(host)
      @counters           = PropertyCounters.new(0, 0, 0)
      @processed          = []
      @purge              = true
      @skipped_properties = SkippedProperties.new
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
    #
    # * the property is skipped (by the block or not). In this case, start does nothing
    #   with the property
    #
    # Returns the result from Workers::OperationRunner#perform if all is well and
    # property is not skipped
    def start(identifier)
      new_context(identifier) do
        result = yield(self)
        return result if skipped_properties.skipped?(identifier) || processed.include?(identifier)
        finish_property_sync(result, identifier)
      end
    end

    # indicates that the synchronisation process failed. As a consequence:
    #
    # * no purging is done when +finish!+ is called.
    # * the corresponding +sync_process+ record will indicate that this process
    #   failed
    def failed!
      sync_record.successful = false
      skip_purge!
    end

    # indicates that purging should not be performed when +finish!+ is called.
    # Useful for synchronisation process that are customised and where the
    # cleanup logic does not fit the flow expected by this class. Purging is
    # then needs to be implemented separately by the supplier implementation.
    def skip_purge!
      @purge = false
    end

    # finishes the synchronisation process. This method should only be called
    # when all properties from the host have already been processed (through
    # the use of +start+). It checks which properties need to be disabled,
    # and processes the corresponding operations.
    #
    # Note that if one of the properties processed failed (i.e., returned a
    # non-successful +Result+), then this process will not disable all properties
    # on Roomorama (rationale: if a supplier faces an intermittent issue during
    # the synchronisation process, we do not want to disable all properties
    # as a consequence of that.)
    #
    # This also persists an entry on the +sync_processes+, registering the completion
    # of the synchronisation process, with the number of properties created/updated/
    # deleted, collected during the process.
    def finish!
      purge_properties
      save_sync_process
    end

    # Allows client to count skipped (not instant bookable, etc) properties during sync process,
    # skipped counter will be saved at the end of sync process. Properties won't be sent to Roomorama,
    # and at the end of the sync, existing properties may be purged.
    #
    # Compare this with #mark_as_processed, where property also will not be sent to Roomorama,
    # but will not be purged.
    #
    # start method ignores skipped properties.
    # The method returns +Result(true)+ to allow developer to
    # interrupt start's block with return like this:
    #
    # sync.start(property_id) do
    #   details = importer.fetch_details(property_id)
    #   return skip_property(property_id, 'On request only') if on_request_only?(details)
    #   ...
    # end
    #
    # Usage:
    #
    # if permissions_validator(permissions.value).valid?
    #   synchronisation.start(property_id) do
    #    ...
    #   end
    # else
    #   synchronisation.skip_property
    # end
    #
    def skip_property(property_id, reason)
      skipped_properties.add(property_id, reason)
      Result.new(true)
    end

    # Allows client to mark a property as having been processed to avoid being purged.
    # Property will not be sent to Roomorama (for update or disable)
    # This is a convenient method to invoke when we know the property should
    # not be purged, but we cannot/do not want to build the Roomorama::Property
    # for the #start block.
    #
    # Compare this with #skip_property, where property is also not sent to Roomorama, but
    # can be purged.
    #
    # Usage:
    #
    #   sync.start(id) do
    #     result = fetch_data
    #     if result.error.code = "rate_limit" && should_try_again_next_sync
    #       sync.mark_as_processed(id)
    #     else
    #       # continue building a Roomorama::Property
    #     end
    #   end
    #
    def mark_as_processed(property_id)
      processed << property_id
    end

    # Used to initialize a clean context for a property id.
    #
    # Users of synchronisation should call this for work related
    # to the host and property identifier, that could create ExternalError:
    #
    #   sync.new_context(property_id) do
    #     # .. do stuff that might announce ExternalErrors
    #   end
    #
    # This is already called in #start, so only call this
    # for work done outside of #start.
    def new_context(identifier=nil)
      Concierge.context = Concierge::Context.new(type: "batch")
      Rollbar.scope!(property_identifier: identifier)

      sync_process = Concierge::Context::SyncProcess.new(
        worker:     WORKER_TYPE,
        host_id:    host.id,
        identifier: identifier
      )

      Concierge.context.augment(sync_process)
      yield
    end

    private

    def finish_property_sync(result, property_id)
      if result.success?
        property = result.value
        process(property)
      else
        sync_record.successful = false
        mark_as_processed(property_id)
        announce_failure(result)
        result
      end
    end

    # when a new property is pushed for synchronisation, this class register
    # the identifier of that property so that, when +finish!+ is called,
    # it is able to know which properties should be disabled.
    #
    # It uses +Workers::Router+ to determine which operation should be
    # performed on the property, if any, and runs it.
    #
    # It returns the result from Workers::OperationRunner#perform
    # or a Result.error(:no_operation) if router couldnt' find a suitable
    # operation to dispatch
    def push(property)
      processed << property.identifier

      operation = router.dispatch(property)

      if operation
        run_operation(operation, property).tap do |result|
          update_counters(operation) if result.success?
        end
      else
        Result.error(:no_operation)
      end
    end

    def process(property)
      property.validate!
      push(property)
    rescue Roomorama::Error => err
      missing_data(err.message, property.to_h)
      Result.error(:missing_data, err.message).tap do |error|
        announce_failure(error)
      end
    end

    def purge_properties
      return unless purge

      purge = all_identifiers - processed

      unless purge.empty?
        result = run_operation(disable_op(purge))
        counters.deleted = purge.size if result.success?
      end
    end

    def save_sync_process
      database = Concierge::OptionalDatabaseAccess.new(SyncProcessRepository)

      sync_record.stats[:properties_created] = counters.created
      sync_record.stats[:properties_updated] = counters.updated
      sync_record.stats[:properties_deleted] = counters.deleted
      sync_record.stats[:properties_skipped] = skipped_properties.to_a
      sync_record.finished_at = Time.now

      database.create(sync_record)
    end

    def run_operation(operation, *args)
      # enable context tracking when performing API calls to Roomorama so that
      # any errors during the request can be logged.
      Concierge.context.enable!

      Workers::OperationRunner.new(host).perform(operation, *args).tap do |result|
        announce_failure(result) unless result.success?
      end
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
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now,
      })
    end

    def all_identifiers
      PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
    end

    def disable_op(identifiers)
      Roomorama::Client::Operations.disable(identifiers)
    end

    def update_counters(operation)
      case operation
      when Roomorama::Client::Operations::Publish
        counters.created += 1
      when Roomorama::Client::Operations::Diff
        counters.updated += 1
      end
    end

    def init_sync_record(host)
      SyncProcess.new(
        type:       WORKER_TYPE,
        host_id:    host.id,
        started_at: Time.now,
        successful: true,
        stats:      {}
      )
    end
  end
end
