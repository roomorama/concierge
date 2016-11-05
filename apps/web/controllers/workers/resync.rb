module Web::Controllers::Workers
  class Resync
    include Web::Action
    include Web::Controllers::InternalError

    def call(params)
      worker = find_worker(params.get("worker.worker_id"))

      if worker
        if worker.idle?
          trigger_sync!(worker)

          flash[:notice] = "#{worker.type} worker with id #{worker.id} was queued to synchronisation"
        else
          flash[:error] = "#{worker.type} worker with id #{worker.id} cannot be queued because it has #{worker.status} status"
        end
      else
        flash[:error] = "Couldn't find requested worker"
      end

      redirect_to routes.supplier_path(params[:supplier_id])
    end

    private
    def find_worker(worker_id)
      BackgroundWorkerRepository.find(worker_id)
    end

    def trigger_sync!(worker)
      enqueue(worker)
      update_status(worker)
    end

    def enqueue(worker)
      element = Workers::Queue::Element.new(
        operation: "background_worker",
        data:      { background_worker_id: worker.id }
      )

      queue.add(element)
    end

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
