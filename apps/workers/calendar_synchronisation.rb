module Workers

  # +Workers::CalendarSynchronisation+
  #
  # Organizes the updating of the availabilities calendar calendar at Roomorama.
  # It is able to validate the calendar for required data presence and perform API
  # calls to Roomorama.
  #
  # Usage
  #
  #   host = Host.last
  #   sync = Workers::CalendarSynchronisation.new(host)
  #
  #   # supplier API is called, availabilities/rates data is fetched
  #   sync.start(property.identifier) do
  #     remote_calendar = fetch_calendar(property)
  #     calendar = Roomorama::Calendar.new(property.identifier)
  #     remote_calendar[:dates].each do |data|
  #       entry = Roomorama::Calendar::Entry.new(
  #         date:         data[:date],
  #         available:    data[:available],
  #         nightly_rate: data[:nightly_price]
  #       )
  #     end
  #   end
  #
  #   sync.finish! # => synchronisation process record is stored on Concierge
  class CalendarSynchronisation

    # the worker type to be stored in the sync processes table for later analysis.
    WORKER_TYPE = "availabilities"

    attr_reader :host, :sync_record, :processed, :counters

    AvailabilityCounters = Struct.new(:available, :unavailable)

    # host - an instance of +Host+.
    def initialize(host)
      @host        = host
      @sync_record = init_sync_record(host)
      @processed   = 0
      @counters    = AvailabilityCounters.new(0, 0)
    end

    # starts the process of fetching the calendar of availabilities for
    # a given property.
    #
    # +identifier+ - the property identifier for which the calendar is being processed.
    #
    # A block should be given to this method and it should return an instance of +Result+.
    # When fetching and parsing the availabilities calendar from the supplier is successful,
    # the +Result+ instance should wrap a +Roomorama::Calendar+ instance. If the returned
    # result is not successful, an external error is persisted to the database and the method
    # terminates with no API calls being performed to Roomorama.
    def start(identifier)
      initialize_context(identifier)
      result = yield(self)
      @processed += 1

      if result.success?
        calendar = result.value
        process(calendar)
      else
        announce_failure(result)
        false
      end
    end

    # terminates the calendar synchronisation process. This method saves a +SyncProcess+
    # record on the database for later analysis, including the number of properties
    # processed, as well as the number of available/unavailable records created.
    def finish!
      database = Concierge::OptionalDatabaseAccess.new(SyncProcessRepository)

      sync_record.properties_created = 0
      sync_record.properties_updated = 0
      sync_record.properties_deleted = 0

      sync_record.stats[:properties_processed] = processed
      sync_record.stats[:available_records]    = counters.available
      sync_record.stats[:unavailable_records]  = counters.unavailable

      sync_record.finished_at = Time.now

      database.create(sync_record)
      true
    end

    private

    def process(calendar)
      calendar.validate!
      update_counters(calendar)
      operation = Roomorama::Client::Operations.update_calendar(calendar)

      run_operation(operation)
    rescue Roomorama::Error => err
      missing_data(err.message, calendar.to_h)
      announce_failure(Result.error(:missing_data))
      false
    end

    def update_counters(calendar)
      data    = calendar.to_h
      mapping = data[:availabilities].to_s.chars.group_by(&:to_s)

      counters.available   += Array(mapping["1"]).size
      counters.unavailable += Array(mapping["0"]).size
    end

    def initialize_context(identifier)
      Concierge.context = Concierge::Context.new(type: "batch")

      sync_process = Concierge::Context::SyncProcess.new(
        worker:     WORKER_TYPE,
        host_id:    host.id,
        identifier: identifier
      )

      Concierge.context.augment(sync_process)
    end

    def run_operation(operation)
      # enable context tracking when performing API calls to Roomorama so that
      # any errors during the request can be logged.
      Concierge.context.enable!

      result = Workers::OperationRunner.new(host).perform(operation, operation.calendar)
      announce_failure(result) unless result.success?
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
        context:     Concierge.context.to_h,
        happened_at: Time.now,
      })
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
