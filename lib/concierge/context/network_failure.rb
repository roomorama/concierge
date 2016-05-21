class Concierge::Context

  # +Concierge::Context::NetworkFailure+
  #
  # In some situations, a network call cannot be completed due to a number of
  # possible reasons:
  #
  # * the remote servers are unavailable
  # * the local server has no internet connection
  # * the request times out
  # * etc..
  #
  #
  # In such scenarions, there is no context of a full HTTP response. This
  # context class records such kinds of failures. It expects a message
  # describing the failure.
  class NetworkFailure

    CONTEXT_TYPE = "network_failure"

    attr_reader :message

    # message - a string describing the network failure. Often, this is going
    # to be the exception error message raised by the underlying HTTP client library.
    def initialize(message:)
      @message = message
    end

    def to_h
      {
        type:    CONTEXT_TYPE,
        message: message
      }
    end

  end

end
