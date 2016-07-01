module API::Views

  class Cancel
    include API::View

    def render
      response = {
        status:     "ok",
        booking_id: cancelled_reservation_id
      }

      json(response)
    end

  end

end
