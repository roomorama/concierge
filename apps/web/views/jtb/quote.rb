module Web::Views::Jtb
  class Quote
    include Web::View

    format :json

    def render
      quotation.to_json
    end

  end
end
