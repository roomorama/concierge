module Web::Views

  class Quote
    include Web::View
    layout false

    def render
      if quotation.successful?
        response = quotation_attributes
      else
        response = errors
      end

      json(response)
    end

    private

    def errors
      { status: "error" }.merge!(errors: quotation.errors)
    end

    def quotation_attributes
      {
        status:     "ok",
        check_in:   quotation.check_in,
        check_out:  quotation.check_out,
        guests:     quotation.guests,
        currency:   quotation.currency,
        total:      quotation.total
      }
    end

  end

end
