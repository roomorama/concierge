require_relative "../internal_error"

module Web::Controllers::Reservations
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    expose :reservations

    def call(params)
      @reservations = ReservationRepository.reverse_date
    end
  end
end
