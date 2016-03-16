module API::Views

  class Booking
    include API::View

    def render
      response = {
        status:      "ok",
        code:        reservation.code,
        property_id: reservation.property_id,
        unit_id:     reservation.unit_id,
        check_in:    reservation.check_in,
        check_out:   reservation.check_out,
        guests:      reservation.guests,
        customer:    reservation.customer
      }

      json(response)
    end

  end

end
