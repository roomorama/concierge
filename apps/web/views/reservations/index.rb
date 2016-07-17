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
      reservation.created_at.strftime("%B %d, %Y at %H:%M")
    end
  end
end
