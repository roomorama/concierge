module Web::Controllers::SyncProcesses
  class Stats
    include Web::Action

    expose :sync_process

    def call(params)
      @sync_process = SyncProcessRepository.find(params[:id])

      halt 404 unless @sync_process
    end
  end
end
