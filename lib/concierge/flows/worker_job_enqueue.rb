module Concierge::Flows
  class WorkerJobEnqueue
    attr_reader :worker

    def initialize(worker)
      @worker = worker
    end

    def perform
      enqueue(worker)
      update_status(worker)
    end

    private
    def enqueue(worker)
      element = Workers::Queue::Element.new(
        operation: "background_worker",
        data:      { background_worker_id: worker.id }
      )

      queue.add(element)
    end

    # Marks the worker as +queued+ so that, if the worker is not processed by
    # the time the scheduler runs again, the same worker will not be enqueued,
    # causing unneeded processing.
    def update_status(worker)
      worker.status = "queued"
      BackgroundWorkerRepository.update(worker)
    end

    def queue
      @queue ||= begin
        credentials = Concierge::Credentials.for("sqs")
        Workers::Queue.new(credentials)
      end
    end
  end
end
