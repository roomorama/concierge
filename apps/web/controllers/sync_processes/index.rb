require_relative "../internal_error"
require_relative "../params/paginated"

module Web::Controllers::SyncProcesses
  class Index
    include Web::Action

    params do
      include Web::Controllers::Params::Paginated
      param :host_id, type: Integer
    end

    expose :metadata_processes, :availabilities_processes

    def call(params)
      page = params[:page]
      per  = params[:per]

      @metadata_processes = SyncProcessRepository.
        most_recent.
        paginate(page: page, per: per).
        of_type("metadata")

      @availabilities_processes = SyncProcessRepository.
        most_recent.
        paginate(page: page, per: per).
        of_type("availabilities")
      if params[:host_id]
        @metadata_processes.for_host(HostRepository.find params[:host_id])
        @availabilities_processes.for_host(HostRepository.find params[:host_id])
      end
    end
  end
end
