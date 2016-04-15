module Concierge

  # +Concierge::EmergencyLog+
  #
  # This class writes to a log file when a situation considered as an emergency
  # happens. Data logged to this file should be used to aid in debugging in error
  # situations, recoverable or not.
  #
  # Usage
  #
  #   log = Concierge::EmergencyLog.new
  #   begin
  #     dangerous_operation!
  #   rescue Some::Error => err
  #     event = Concierge::EmergencyLog::Event.new
  #     event.type = "network_error"
  #     event.description = "something went wrong when connecting to some service"
  #     event.messages = e.backtrace
  #
  #     log.report(event)
  #   end
  #
  # Logged messages are kept under +log/emergency_log.{env}+, where +env+
  # is the Hanami environment. Apart from that, errors reported through the
  # emergency log are also reported on Rollbar on +critical+ level.
  class EmergencyLog
    class << self
      attr_writer :logger

      # Reuse the same logger across multiple instances of +Concierge::EmergencyLog+
      def logger
        @logger ||= build_logger
      end

      private

      # By default, emergency messages are logged to a file under the +log+
      # directory. The default logger uses a custom message formatter
      # which accepts a +Concierge::EmergencyLog::Event+ instance, and
      # formats it accordingly.
      def build_logger
        path = Hanami.root.join("log", ["emergency_log.", Hanami.env].join)
        Logger.new(path).tap do |logger|
          logger.formatter = ->(_, timestamp, _, event) {
            messages = Array(event.messages)
            if messages.empty?
              messages = nil
            end

            [
              "[#{timestamp}] Emergency error",
              ["Type: ", event.type].join,
              ["Description: ", event.description].join,
              messages
            ].flatten.compact.join("\n")
          }
        end
      end
    end

    # data structure used to encapsulate an emergency event that needs to be reported.
    #
    # type        - an error identifier.
    # description - a longer description of the error.
    # messages    - a list of complementary messages associated with the event.
    Event = Struct.new(:type, :description, :messages)

    def report(event)
      logger.error(event)
      Rollbar.critical("Emergency Log: #{event.type}")
    end

    private

    def logger
      self.class.logger
    end
  end

end
