require_relative "../internal_error"

module Web::Controllers::SyncProcesses
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    params do
      param :p,    type: Integer # p: the page number
      param :page, type: Integer # per: how many records per page
    end

    expose :metadata_processes, :availabilities_processes

    def call(params)
      page = params[:p]   && params[:p].to_i
      per  = params[:per] && params[:per].to_i

      scope = SyncProcessRepository.most_recent.paginate(page: page, per: per)

      @metadata_processes  = SyncProcessRepository.
        most_recent.
        paginate(page: page, per: per).
        of_type("metadata")

      @availabilities_processes  = SyncProcessRepository.
        most_recent.
        paginate(page: page, per: per).
        of_type("availabilities")
    end
  end
end
