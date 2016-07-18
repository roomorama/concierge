require_relative "../internal_error"

module Web::Controllers::Reservations
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    params do
      param :p,    type: Integer # p: the page number
      param :page, type: Integer # per: how many records per page
    end

    expose :reservations

    def call(params)
      page = params[:p]   && params[:p].to_i
      per  = params[:per] && params[:per].to_i

      @reservations = ReservationRepository.reverse_date.paginate(page: page, per: per)
    end
  end
end
