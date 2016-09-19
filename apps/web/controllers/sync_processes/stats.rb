module Web::Controllers::SyncProcesses
  class Stats
    include Web::Action
    include Web::Controllers::InternalError

    expose :sync_process

    def call(params)
      @sync_process = SyncProcessRepository.find(params[:id])
    end
  end
end
