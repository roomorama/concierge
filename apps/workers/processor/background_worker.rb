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
        [host]
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
        [supplier]
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
      worker = BackgroundWorkerRepository.find(data[:background_worker_id])
      return Result.new(true) if worker.running?

      runner = runner_for(worker)

      running(worker) do
        timing_out(worker.type, data) do
          supplier  = runner.supplier
          broadcast = [worker.type, ".", supplier.name].join

          Concierge::Announcer.trigger(broadcast, *runner.args)
          Result.new(true)
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
    # according to the specified worker +interval+.
    def running(worker)
      worker_started(worker)
      yield

    ensure
      # reload the worker instance to make sure to account for any possible
      # changes in the process
      worker_completed(BackgroundWorkerRepository.find(worker.id))
    end

    def worker_started(worker)
      worker.status = "running"
      BackgroundWorkerRepository.update(worker)
    end

    def worker_completed(worker)
      worker.status      = "idle"
      worker.next_run_at = Time.now + worker.interval

      BackgroundWorkerRepository.update(worker)
    end

    # NOTE this time out should be shorter than the +VisibilityTimeout+ configured
    # on the SQS queue to be used by Concierge.
    def processing_timeout
      @two_hour ||= 60 * 60 * 2
    end
  end
end
