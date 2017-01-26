require_relative "../internal_error"
require_relative "../params/paginated"

module Web::Controllers::SyncProcesses
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    params do
      include Web::Controllers::Params::Paginated
      param :host_id, type: Integer
    end

    expose :metadata_processes, :availabilities_processes

    def call(params)
      page = params[:page]
      per  = params[:per]

      relevant_meta_processes = SyncProcessRepository
      relevant_meta_processes = relevant_meta_processes.for_host(HostRepository.find params[:host_id]) if params[:host_id]
      @metadata_processes = relevant_meta_processes.
        most_recent.
        paginate(page: page, per: per).
        of_type("metadata")

      relevant_avail_processes = SyncProcessRepository
      relevant_avail_processes = relevant_avail_processes.for_host(HostRepository.find params[:host_id]) if params[:host_id]
      @availabilities_processes = relevant_avail_processes.
        most_recent.
        paginate(page: page, per: per).
        of_type("availabilities")
    end
  end
end
