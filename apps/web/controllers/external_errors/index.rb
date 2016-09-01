require_relative "../internal_error"
require_relative "../params/paginated"

module Web::Controllers::ExternalErrors
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    params do
      include Web::Controllers::Params::Paginated
      param :supplier, type: String
      param :code,     type: String
    end

    expose :external_errors

    def call(params)
      relevant_errors = ExternalErrorRepository.reverse_occurrence

      relevant_errors = relevant_errors.from_supplier_named(params[:supplier]) if params[:supplier]
      relevant_errors = relevant_errors.with_code(params[:code])               if params[:code]

      @external_errors = relevant_errors.paginate(page: params[:page], per: params[:per])
    end
  end
end
