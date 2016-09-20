require_relative "../internal_error"

module Web::Controllers::ExternalErrors
  class Show
    include Web::Action
    include Web::Controllers::InternalError

    expose :error

    def call(params)
      @error = ExternalErrorRepository.find(params[:id])

      halt 404 unless @error
    end
  end
end
