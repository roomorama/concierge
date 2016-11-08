class Concierge::Context

  # +Concierge::Context::Message+
  #
  # This class encapsulates an event that does not fit the predefind categories,
  # and can be defined as a message to be print with further information.
  # By default content type of message is plain text, but it also can be json or xml.
  #
  # Usage
  #
  #   mismatch = Concierge::Context::Message.new(
  #     label:        "Parsing failure",
  #     message:      "Failed to parse init file."
  #     backtrace:    caller,
  #     content_type: 'json'
  #   )
  class Message

    CONTEXT_TYPE = "generic_message"

    attr_reader :label, :message, :backtrace, :timestamp, :content_type

    def initialize(label:, message:, backtrace:, content_type: 'plain')
      @label        = label
      @message      = message
      @content_type = content_type
      @backtrace    = scrub(backtrace)
      @timestamp    = Time.now
    end

    def to_h
      {
        type:         CONTEXT_TYPE,
        timestamp:    timestamp,
        label:        label,
        message:      message,
        backtrace:    backtrace,
        content_type: content_type
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
