require_relative "../internal_error"
require_relative "../params/paginated"

module Web::Controllers::ExternalErrors
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    params Web::Controllers::Params::Paginated

    expose :external_errors

    def call(params)
      page = params[:page] && params[:page].to_i
      per  = params[:per]  && params[:per].to_i

      @external_errors = ExternalErrorRepository.reverse_occurrence.paginate(page: page, per: per)
    end
  end
end
