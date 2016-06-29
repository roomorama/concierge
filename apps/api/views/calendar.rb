module API::Views

  class Calendar
    include API::View

    def render
      entries  = calendar.entries.map { |entry| render_calendar_entry(entry) }
      response = { calendar: entries }

      json(response)
    end

    private

    def render_calendar_entry(entry)
      {
        date:             entry.date,
        available:        entry.available,
        nightly_rate:     entry.nightly_rate,
        weekly_rate:      entry.weekly_rate,
        monthly_rate:     entry.monthly_rate,
        checkin_allowed:  entry.checkin_allowed,
        checkout_allowed: entry.checkout_allowed
      }
    end

  end

end
