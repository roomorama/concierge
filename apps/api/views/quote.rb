module API::Views

  class Quote
    include API::View
    layout false

    def render
      json({
        status:     "ok",
        check_in:   quotation.check_in,
        check_out:  quotation.check_out,
        guests:     quotation.guests,
        currency:   quotation.currency,
        total:      quotation.total
      })
    end

  end

end
