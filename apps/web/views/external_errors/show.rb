module Web::Views::ExternalErrors

  # +Web::Views::ExternalErrors::Show+
  #
  # The external errors show page displays the error time line, as collected
  # by the API context, wrapped by +Concierge::Context+.
  #
  # Each event type, under +Concierge::Context+ has its own presenter, allowing
  # a detailed timeline of the error occurrence to be presented, helping the
  # debugging process.
  class Show
    include Web::View
  end
end
