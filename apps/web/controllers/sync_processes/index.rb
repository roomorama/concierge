require_relative "../internal_error"
require_relative "../params/paginated"

module Web::Controllers::SyncProcesses
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    params do
      include Web::Controllers::Params::Paginated
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
    end
  end
end
