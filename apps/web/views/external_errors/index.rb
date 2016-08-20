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
      time_formatter.present(error.happened_at)
    end

    # receives an instance of +ExternalError+ and generates a link to the
    # +show+ page of that error.
    def error_link(error)
      name = ["#", error.id].join
      link_to name, routes.error_path(error.id)
    end

    # next page link
    def next_link(cur_page)
      next_page = cur_page.to_i <= 0 ? 2 : cur_page.to_i + 1
      link_to 'Next ❯', routes.errors_path({page: next_page})
    end

    # prev page link
    def prev_link(cur_page)
      prev_page = cur_page.to_i - 1
      link_to '❮ Prev', routes.errors_path({page: prev_page}) if prev_page > 0
    end

    private

    def time_formatter
      @time_formatter ||= Web::Support::Formatters::Time.new
    end
  end
end
