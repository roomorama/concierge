class Concierge::Context

  # +Concierge::Context::ResponseMismatch+
  #
  # This class encapsulates the event where a response from a supplier API
  # does not meet the expected format. That could be due to a number of reasons:
  #
  # * the response could not be parsed
  # * a required field was not present
  # * the format of a field was not as expected
  # * among others.
  #
  # As this is the most intricate kind of issue, it also accepts information of
  # the runtime execution backtrace. That allows later analysis to pinpoint the
  # exact location of where the incompatibility was raised. Backtraces are cleaned
  # so that only entries related to Concierge are reported - framework or application
  # server backtrace is not included.
  #
  # Usage
  #
  #   mismatch = Concierge::Context::ResponseMismatch.new(
  #     message: "Expected a non-null value for field `description`",
  #     backtrace: caller
  #   )
  class ResponseMismatch

    CONTEXT_TYPE = "response_mismatch"
    LABEL        = "Response Mismatch"

    attr_reader :message

    # a thin wrapper around the generic +message+ event type.
    def initialize(message:, backtrace:)
      @message = Concierge::Context::Message.new(
        label:     LABEL,
        message:   message,
        backtrace: backtrace
      )
    end

    def to_h
      message.to_h.merge!(type: CONTEXT_TYPE)
    end

  end

end
