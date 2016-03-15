module API::Views

  class Booking
    include API::View

    def render
      response = {
        status:    "ok",
        code:      reservation.code,
        quotation: reservation.quotation,
        customer:  reservation.customer
      }

      json(response)
    end

  end

end
