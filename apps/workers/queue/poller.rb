class Workers::Queue

  # +Workers::Queue::Poller+
  #
  # Wraps the function of polling for incoming messages of a given queue. Thin wrapper
  # over +Aws::SQS::QueuePoller+
  class Poller

    # +Workers::Queue::Poller::InvalidQueueProcessingResultError+
    #
    # This is raised by +Workers::Queue::Poller+ when doing a +poll+ and the block
    # invoked to process an incoming result does not return a valid instance
    # of +Result+, as it should.
    class InvalidQueueProcessingResultError < StandardError
      def initialize(object)
        super("Queue processing must return a Result instance, returned instead #{object.class}")
      end
    end

    # queue_url - a String containing the URL to the queue to be monitored
    # client    - an +Aws::SQS::Client+ instance
    def initialize(queue_url, client)
      @queue_url = queue_url
      @client    = client
    end

    # runs the given block before any request to SQS is performed. As with the
    # underlying +Aws::SQS::QueuePoller+ class, a block given to this method
    # can +throw+ the +:stop_polling+ message, causing the polling process
    # to halt.
    def before
      poller.before_request { |stats| yield(stats) }
    end

    # wraps the logic behind polling an SQS queue by receiving each message
    # and yielding it back to the caller.
    #
    # The invoked block *must* return a +Result+ instance, indicating whether
    # or not the message processing was successful. In case it was, the message
    # is deleted from the queue; otherwise, it remains in the queue for later
    # processing.
    def poll
      poller.poll(skip_delete: true) do |message|
        result = yield(message)
        ensure_result!(result)

        if result.success?
          poller.delete_message(message)
        end
      end
    end

    private

    def poller
      @poller ||= Aws::SQS::QueuePoller.new(queue_url, client)
    end

    # ensures that the given +object+ is a valid instance of +Result+. Necessary to
    # catch early on errors where the message processing block does not return
    # a valid +Result+ instance.
    def ensure_result!(object)
      unless object.is_a?(Result)
        raise InvalidQueueProcessingResultError.new(object)
      end
    end

  end
end
