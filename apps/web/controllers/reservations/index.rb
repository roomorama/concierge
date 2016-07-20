require_relative "../internal_error"
require_relative "../params/paginated"

module Web::Controllers::Reservations
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    params Web::Controllers::Params::Paginated

    expose :reservations

    def call(params)
      page = params[:page] && params[:page].to_i
      per  = params[:per]  && params[:per].to_i

      @reservations = ReservationRepository.reverse_date.paginate(page: page, per: per)
    end
  end
end
