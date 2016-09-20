require "timeout"

module Workers

  # +Workers::Processor+
  #
  # This class wraps the logic of processing one message read from the +Concierge::Queue+
  # (backed by an SQS queue) class. By default (as specified by +Concierge::Queue::Element+),
  # each message is a JSON-encoded string containing two fields:
  #
  # +operation+ - the identifier of the operation to be performed. Only +sync+ is supported
  #               at the moment.
  # +data+      - a map of values to be used as arguments of the given +operation+. For the
  #               +sync+ operation, this map contains only one key, +host_id+, the ID of the
  #               host that is to be synchronised.
  #
  # Example
  #
  #   queue = Concierge::Queue.new(credentials)
  #   queue.poll do |message|
  #     Workers::Processor.new(message).process!
  #   end
  class Processor

    # +Workers::Processor::UnknownOperationError+
    #
    # Error raised when an operation read from the queue, given to +Workers::Processor+
    # is unrecognised.
    class UnknownOperationError < StandardError
      def initialize(operation)
        super("Queue received unrecognised operation #{operation}")
      end
    end

    class TimeoutError < StandardError
      def initialize(operation, params)
        super("Processing of operation #{operation}, with args #{params} timed out.")
      end
    end

    include Concierge::JSON

    attr_reader :payload

    # json - a JSON encoded string, read directly from the queue.
    def initialize(json)
      @payload = json
    end

    # processes the message. For the +sync+ operation, all that is done is
    # to trigger the +sync.<supplier_name>+ event on +Concierge::Announcer+.
    # If there is an implementation listening for this event, it will be
    # processed.
    #
    # Returns a +Result+ instance with any potential error.
    def process!
      return message unless message.success?
      element = Concierge::SafeAccessHash.new(message.value)

      if element[:operation] == "background_worker"
        Processor::BackgroundWorker.new(element[:data]).run
      elsif element[:operation] == "pdf"
        Processor::Pdf.new(element[:data]).run
      else
        raise UnknownOperationError.new(element[:operation])
      end
    end

    private

    def message
      @message = json_decode(payload)
    end
  end
end
