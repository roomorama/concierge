require_relative "../internal_error"

module Web::Controllers::Workers
  class Resync
    include Web::Action
    include Web::Controllers::InternalError

    def call(params)
      worker = find_worker(params.get("worker.worker_id"))

      if worker
        if worker.idle?
          Concierge::Flows::WorkerJobEnqueue.new(worker).perform

          flash[:notice] = "#{worker.type} worker with id #{worker.id} was queued to synchronisation"
        else
          flash[:error] = "#{worker.type} worker with id #{worker.id} cannot be queued because it has #{worker.status} status"
        end
      else
        flash[:error] = "Couldn't find requested worker"
      end

      redirect_to request.referer
    end

    private
    def find_worker(worker_id)
      BackgroundWorkerRepository.find(worker_id)
    end

  end
end
