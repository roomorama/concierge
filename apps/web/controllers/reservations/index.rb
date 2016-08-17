require_relative "../internal_error"
require_relative "../params/paginated"

module Web::Controllers::Reservations
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    params do
      include Web::Controllers::Params::Paginated
    end

    expose :reservations

    def call(params)
      @reservations = ReservationRepository.reverse_date.paginate(page: params[:page], per: params[:per])
    end
  end
end
