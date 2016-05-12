module Web::Views::Dashboard
  class Index
    include Web::View

    def concierge_ping
      label(success: "Up", failure: "Down") { concierge.alive? }
    end

    def concierge_healthy
      label(success: "Yes", failure: "No") { concierge.healthy? }
    end

    private

    def label(success:, failure:)
      if yield
        html.span success, class: "concierge-success"
      else
        html.span failure, class: "concierge-failure"
      end
    end
  end
end
