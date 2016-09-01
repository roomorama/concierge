module Workers

  # +Workers::Scheduler+
  #
  # This class is responsible for checking which background workers should be run
  # (i.e., the +next_run_at+ column is either +nil+ or in a time in the past),
  # and enqueue the correspondent message to the queue to start the
  # synchronisation process.
  #
  # This scheduler logs its work using a +logger+ instance given on initialization.
  # By default, its output is placed on +log/scheduler.log+. Activity on which
  # hosts were synchronised can be checked from there.
  class Scheduler

    # the logger classes below aim to provide a unique interface for generating
    # log messages for host and supplier-related workers. The methods expected to
    # be implemented are:
    #
    # +initialize(worker)+
    # Initializes the logger, receiving an instance of +BackgroundWorker+
    #
    # +to_s+
    # Returns a +String+ with the scheduler message to be logged.

    # +Workers::Scheduler::HostLogger+
    #
    # Generates log messages for host background workers being scheduled.
    class HostLogger
      attr_reader :worker

      def initialize(worker)
        @worker = worker
      end

      def to_s
        host = HostRepository.find(worker.host_id)

        "action=%s host.username=%s host.identifier=%s" %
          [worker.type, host.username, host.identifier]
      end
    end

    # +Workers::Scheduler::SupplierLogger+
    #
    # Generates log messages for supplier background workers (+aggregated+ type)
    # being scheduled.
    class SupplierLogger
      attr_reader :worker

      def initialize(worker)
        @worker = worker
      end

      def to_s
        supplier = SupplierRepository.find(worker.supplier_id)
        "action=%s supplier.name=%s" % [worker.type, supplier.name]
      end
    end

    # the default path to the file where the logs of this class are written.
    LOG_PATH = Hanami.root.join("log", "scheduler.log").to_s

    attr_reader :logger

    # logger - if given, it should be +Logger+ instance.
    def initialize(logger: default_logger)
      @logger = logger
    end

    # queries the +hosts+ table to identify which host should be synchronised,
    # enqueueing messages if necessary.
    def trigger_pending!
      BackgroundWorkerRepository.pending.each do |background_worker|
        log_event(background_worker)
        enqueue(background_worker)
      end
    end

    private

    def default_logger
      ::Logger.new(LOG_PATH)
    end

    def enqueue(worker)
      element = Workers::Queue::Element.new(
        operation: "background_worker",
        data:      { background_worker_id: worker.id }
      )

      queue.add(element)
    end

    def log_event(worker)
      host = HostRepository.find(worker.host_id)
      entity_logger = entity_logger_for(worker)

      logger.info(entity_logger.to_s)
    end

    def queue
      @queue ||= begin
        credentials = Concierge::Credentials.for("sqs")
        Workers::Queue.new(credentials)
      end
    end

    def entity_logger_for(worker)
      if worker.supplier_id
        SupplierLogger.new(worker)
      else
        HostLogger.new(worker)
      end
    end

  end

end
