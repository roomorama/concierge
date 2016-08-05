require_relative "../internal_error"

module Web::Controllers::SyncProcesses
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    params Web::Controllers::Params::Paginated

    expose :metadata_processes, :availabilities_processes

    def call(params)
      page = params[:page] && params[:page].to_i
      per  = params[:per]  && params[:per].to_i

      @metadata_processes = SyncProcessRepository.
        most_recent.
        paginate(page: page, per: per).
        of_type("metadata")

      @availabilities_processes = SyncProcessRepository.
        most_recent.
        paginate(page: page, per: per).
        of_type("availabilities")
    end
  end
end
