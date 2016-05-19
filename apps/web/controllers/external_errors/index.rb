module Web::Controllers::ExternalErrors
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    expose :external_errors

    def call(params)
      page = params[:p]   && params[:p].to_i
      per  = params[:per] && params[:per].to_i

      @external_errors = ExternalErrorRepository.paginate(page: page, per: per)
    end
  end
end
