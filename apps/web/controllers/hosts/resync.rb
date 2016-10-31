module Web::Controllers::Hosts
  class Resync
    include Web::Action
    include Web::Controllers::InternalError

    def call(params)
      host = HostRepository.find(params.get("host.host_id"))

      if host
        trigger_sync!(host)

        flash[:notice] = "Host #{host.identifier} (#{host.username}) was queued to synchronisation"
      else
        flash[:error] = "Couldn't find requested host"
      end

      redirect_to routes.supplier_path(params[:supplier_id])
    end

    private
    def trigger_sync!(host)
      BackgroundWorkerRepository.for_host(host).each do |background_worker|
        log_event(background_worker)
        enqueue(background_worker)
      end
    end
  end
end
