class Concierge::RoomoramaClient

  # +Concierge::RoomoramaClient::Error+
  #
  # Parent class for all errors raised by the Roomorama API client in Concierge.
  # This allows caller to filter any error that might happen during the client's
  # execution.
  class Error < StandardError
  end

end
