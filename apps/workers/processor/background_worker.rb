class Workers::Processor

  # +Workers::Processor::BackgroundWorker+
  #
  # This class is responsible for running background workers (according to
  # the data in the corresponding +BackgroundWorker+ entity.)
  #
  # Background workers can be of two types: associated with a host (regular
  # workers), or associated directly with a supplier (for suppliers declared
  # as +aggregated+.) The corresponding instance of +Host+ and +Supplier+,
  # respectively, is passed to code listening via +Concierge::Announcer+.
  class BackgroundWorker

    WORKER_NOT_FOUND = :invalid_worker_id

    # +Workers::Processor::BackgroundWorker::NotAResultError+
    #
    # Error raised when the implementation of a background worker event is run
    # but does not return an instance of +Result+ as expected.
    class NotAResultError < RuntimeError
      def initialize(event, object)
        super("Listener of event #{event} did not return a Result instance, but instead #{object.class}")
      end
    end

    # +Workers::Processor::BackgroundWorker::NotMappableError+
    #
    # Error raised when the implementation of a background worker event is run
    # and is successful, but the wrapped return is not mappable to a Ruby Hash,
    # that is, it does not respond to the +to_h+ method.
    class NotMappableError < RuntimeError
      def initialize(event, object)
        super("Listener of event #{event} returned #{object.class}, which does not respond to `to_h'")
      end
    end

    # +Workers::Processor::BackgroundWorker::UnknownWorkerError+
    #
    # Error raised when the message read from the queue and processed contains an
    # ID for which there is no corresponding +BackgroundWorker+ record on the
    # database.
    class UnknownWorkerError < RuntimeError
      def initialize(id)
        super("Background worker task with ID #{id}, which does not exist on the database. Skipping.")
      end
    end

    # The classes below are responsible for determining parameters to be used
    # when invoking the correct supplier implementation. They are expected to
    # implement two methods:
    #
    # +initialize(worker)+
    # Receives an instance of +BackgroundWorker+.
    #
    # +supplier+
    # determines the supplier associated with a run of a background worker.
    # For host-associated workers, the supplier is defined as the supplier
    # of the associated hosts; for aggregated-type suppliers, the supplier
    # is just defined as the supplier directly connected to the background
    # worker via the +supplier_id+ foreign key.
    #
    # +args+
    # the list of arguments to be passed to code listening on the related
    # event via +Concierge::Announcer+.

    # +Workers::Processor::BackgroundWorker::HostRunner+
    #
    # For regular, host-associated background workers.
    class HostRunner
      attr_reader :worker

      def initialize(worker)
        @worker = worker
      end

      def supplier
        SupplierRepository.find(host.supplier_id)
      end

      def args
        [host, worker.next_run_args]
      end

      private

      def host
        @host ||= HostRepository.find(worker.host_id)
      end
    end

    # +Workers::Processor::BackgroundWorker::SupplierRunner+
    #
    # For aggregated, supplier-associated background workers.
    class SupplierRunner
      attr_reader :worker

      def initialize(worker)
        @worker = worker
      end

      def supplier
        @supplier ||= SupplierRepository.find(worker.supplier_id)
      end

      def args
        [supplier, worker.next_run_args]
      end
    end

    attr_reader :data

    # data - the map of attributes passed as argument to the background_worker message.
    #        Must contain only one field: +background_worker_id+.
    def initialize(data)
      @data = data
    end

    # reads the +background_worker_id+ argument passed in the message (within the +data+
    # parameter given on initialization), and invokes the +<worker_type>.<supplier_name>+
    # event on +Concierge::Announcer+.
    def run
      worker_lookup = fetch_worker(data[:background_worker_id])
      return worker_lookup if not_found?(worker_lookup)

      worker = worker_lookup.value
      return Result.new(true) if worker.running?

      runner    = runner_for(worker)
      supplier  = runner.supplier
      broadcast = [worker.type, ".", supplier.name].join

      running(broadcast, worker) do
        timing_out(worker.type, data) do
          # gotcha: +Concierge::Announcer#trigger+ returns an array of the results of each
          # listener for the given event. Here, we take the first of them assuming
          # it will be the supplier implementation. That works since there has been no
          # need for a supplier implementation to provide more than one listener for the
          # same event. That is a good practice that allows arguments to be passed
          # from one run to the next.
          Concierge::Announcer.trigger(broadcast, *runner.args).first
        end
      end
    end

    private

    def runner_for(worker)
      if worker.supplier_id
        SupplierRunner.new(worker)
      else
        HostRunner.new(worker)
      end
    end

    # timing out the operation to be processed by the queue makes sure that
    # jobs take too long are not taken by a different worker, possibly duplicating
    # work and causing conflicts.
    def timing_out(operation, params)
      Timeout.timeout(processing_timeout) { yield }
    rescue Timeout::Error
      error = TimeoutError.new(operation, params)
      Rollbar.error(error)

      Result.error(:timeout)
    end

    # coordinates the +BackgroundWorker+ instance status and timestamps by changing
    # the worker status to +running+, yielding the block (which is supposed to do
    # the worker's job), and ensuring that the worker's status is set back to +idle+
    # at the end of the process, as well as properly updating the +next_run_at+ column
    # according to the specified worker +interval+, and the +next_run_args+ column according
    # to what is returned by the event implementation.
    def running(event, worker)
      worker_started(worker)
      result = yield

    rescue => error
      result = Result.error(:integration_error)
      raise error

    ensure
      ensure_valid_result!(event, result)

      # reload the worker instance to make sure to account for any possible
      # changes in the process
      worker_completed(BackgroundWorkerRepository.find(worker.id), result)
    end

    def worker_started(worker)
      worker.status = "running"
      BackgroundWorkerRepository.update(worker)
    end

    def worker_completed(worker, result)
      # it is possible that the worker no longer exists by the time it finished.
      # This happens, for instance, with Kigo Legacy where, during the synchronisation
      # process, the host can be deemed to be inactive. In such scenario the host
      # is deleted, along with any associated background worker.
      return unless worker

      worker.status      = "idle"
      worker.next_run_at = Time.now + worker.interval

      if result.success?
        worker.next_run_args = result.value
      end

      BackgroundWorkerRepository.update(worker)
    end

    # makes sure that the instance returned by an event implementation
    # returns a +Result+ instance, and that the wrapped object responds
    # to +to_h+.
    def ensure_valid_result!(event, instance)
      unless instance.is_a?(Result)
        raise NotAResultError.new(event, instance)
      end

      if instance.success? && !instance.value.respond_to?(:to_h)
        raise NotMappableError.new(event, instance)
      end
    end

    # tries to fetch the worker with the given +id+ from the database. If there
    # is none, notfies the occurrence to Rollbar, and returns a +Result+ wrapping
    # +Workers::Processor::BackgroundWorker::WORKER_NOT_FOUND+.
    def fetch_worker(id)
      worker = BackgroundWorkerRepository.find(id)

      if worker
        Result.new(worker)
      else
        error = UnknownWorkerError.new(id)
        Rollbar.error(error)

        Result.new(WORKER_NOT_FOUND)
      end
    end

    def not_found?(result)
      result.value == WORKER_NOT_FOUND
    end

    # NOTE this time out should be shorter than the +VisibilityTimeout+ configured
    # on the SQS queue to be used by Concierge.
    def processing_timeout
      @two_hour ||= 60 * 60 * 2
    end
  end
end
