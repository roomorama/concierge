module Web::Views::ExternalErrors

  # +Web::Views::ExternalErrors::Index+
  #
  # The external errors page lists the most recent errors that happened
  # on Concierge's execution of its operations - errors stored at the
  # +external_errors+ database table.
  #
  # Errors are paginated and the most recent ones are displayed at the
  # top.
  class Index
    include Web::View

    # Receives an instance of +ExternalError+ and formats the
    # +happened_at+ column for display.
    def format_time(error)
      error.happened_at.strftime("%B %d, %Y at %H:%M")
    end
  end
end
