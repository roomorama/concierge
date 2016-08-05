module Web::Views::Reservations

  # +Web::Views::Reservations::Index+
  #
  # The reservations index page renders a table of database reservations
  # for analysis.
  class Index
    include Web::View

    # Receives an instance of +Reservation+ and formats the
    # +created_at+ column for display.
    def format_time(reservation)
      time_formatter.present(reservation.created_at)
    end

    private

    def time_formatter
      @time_formatter ||= Web::Support::Formatters::Time.new
    end
  end
end
