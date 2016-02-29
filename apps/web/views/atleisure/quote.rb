module Web::Views::AtLeisure

  class Quote
    include Web::View
    layout false

    def render
      json(name: "@Leisure")
    end

  end

end
