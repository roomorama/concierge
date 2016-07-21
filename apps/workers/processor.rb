require "timeout"

module Workers

  # +Workers::Processor+
  #
  # This class wraps the logic of processing one message read from the +Workers::Queue+
  # (backed by an SQS queue) class. By default (as specified by +Workers::Queue::Element+),
  # each message is a JSON-encoded string containing two fields:
  #
  # +operation+ - the identifier of the operation to be performed. Only +sync+ is supported
  #               at the moment.
  # +data+      - a map of values to be used as arguments of the given +operation+. For the
  #               +sync+ operation, this map contains only one key, +host_id+, the ID of the
  #               host that is to be synchronised.
  #
  # Example
  #
  #   queue = Workers::Queue.new(credentials)
  #   queue.poll do |message|
  #     Workers::Processor.new(message).process!
  #   end
  class Processor

    # +Workers::Processor::UnknownOperationError+
    #
    # Error raised when an operation read from the queue, given to +Workers::Processor+
    # is unrecognised.
    class UnknownOperationError < StandardError
      def initialize(operation)
        super("Queue received unrecognised operation #{operation}")
      end
    end

    class TimeoutError < StandardError
      def initialize(operation, params)
        super("Processing of operation #{operation}, with args #{params} timed out.")
      end
    end

    include Concierge::JSON

    attr_reader :payload

    # json - a JSON encoded string, read directly from the queue.
    def initialize(json)
      @payload = json
    end

    # processes the message. For the +sync+ operation, all that is done is
    # to trigger the +sync.<supplier_name>+ event on +Concierge::Announcer+.
    # If there is an implementation listening for this event, it will be
    # processed.
    #
    # Returns a +Result+ instance with any potential error.
    def process!
      return message unless message.success?
      element = Concierge::SafeAccessHash.new(message.value)

      if element[:operation] == "background_worker"
        run_worker(element[:data])
      else
        raise UnknownOperationError.new(element[:operation])
      end
    end

    private

    def run_worker(args)
      worker = BackgroundWorkerRepository.find(args[:background_worker_id])
      return Result.new(true) if worker.running?

      running(worker) do
        timing_out(worker.type, args) do
          host      = HostRepository.find(worker.host_id)
          supplier  = SupplierRepository.find(host.supplier_id)
          broadcast = [worker.type, ".", supplier.name].join

          Concierge::Announcer.trigger(broadcast, host)
          Result.new(true)
        end
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

    def message
      @message = json_decode(payload)
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
