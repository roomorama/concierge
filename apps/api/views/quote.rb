module API::Views

  class Quote
    include API::View

    def render
      response = {
        status:     "ok",
        available:   quotation.available,
        property_id: quotation.property_id,
        unit_id:     quotation.unit_id,
        check_in:    quotation.check_in,
        check_out:   quotation.check_out,
        guests:      quotation.guests
      }

      if quotation.available
        response.merge!({
          currency: quotation.currency,
          total:    quotation.total
        })
      end

      json(response)
    end

  end

end
