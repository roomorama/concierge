module Web::Views::Dashboard

  # +Web::Views::Dashboard::Index+
  #
  # This view is presented on Concierge's dashboard page.
  # It includes information on the status of the API.
  #
  # This view expects an instance of +Web::Support::StatusCheck+
  # for more information on API status check being exposed as
  # +concierge+. Check the documentation of that class for further
  # information on API status check.
  class Index
    include Web::View

    def concierge_ping
      label(success: "Up", failure: "Down") { concierge.alive? }
    end

    def concierge_healthy
      label(success: "Yes", failure: "No") { concierge.healthy? }
    end

    # +concierge.response+ is a +Result+ instance that wraps a
    # +Faraday::Response+ instance.
    def error_message
      unless concierge.response.success?
        error = concierge.response.error
        html.code [error.code, " - ", error.message].join
      end
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
