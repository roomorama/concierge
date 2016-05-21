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

    attr_reader :message, :backtrace

    def initialize(message:, backtrace:)
      @message   = message
      @backtrace = scrub(backtrace)
    end

    def to_h
      {
        type:      CONTEXT_TYPE,
        message:   message,
        backtrace: backtrace
      }
    end

    private

    # removes entries from the backtrace that are not related to Concierge.
    # To that purpose, each line of the backtrace is analysed to check if it
    # includes the root directory along the path - if it does not, then it
    # can be safely removed. Also, the root path of such entries, since
    # repeat on all entries, is removed from them.
    #
    # Example
    #
    #   scrub([
    #     "/data/concierge/current/lib/concierge/jtb/client.rb:293 in get_quote"
    #     "/data/concierge/current/lib/concierge/jtb/client/parser.rb:12 in parse"
    #     "/home/deploy/.rvm/rubies/2.3.0/gems/hanami/loader.rb:3092 in process",
    #     "/home/deploy/.rvm/rubies/2.3.0/gems/unicorn/server.rb:129 in process",
    #     "/home/deploy/.rvm/rubies/2.3.0/gems/unicorn/application.rb:29 in new",
    #   ])
    #
    #   # => ["lib/concierge/jtb/client.rb:293 in get_quote", lib/concierge/jtb/client/parser.rb:12 in parse"]
    #
    # NOTE this assumes that the gems will not be in the same directory as the
    # application. If one day gems start to be vendored inside the application,
    # the logic of this method should be adapted.
    def scrub(backtrace)
      backtrace.
        select { |path| path =~ Regexp.new(Hanami.root.to_s) }.
        map    { |path| path.sub(%r[^#{Hanami.root.to_s}/], "") }
    end

  end

end
