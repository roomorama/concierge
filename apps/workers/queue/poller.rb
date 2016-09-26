class Workers::Queue

  # +Workers::Queue::Poller+
  #
  # Wraps the function of polling for incoming messages of a given queue. Thin wrapper
  # over +Aws::SQS::QueuePoller+
  class Poller

    attr_reader :queue_url, :client

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
    # The message is deleted from the queue as soon as it is received. Implementations
    # of message processing workers must therefore ensure that failed messages are
    # re-enqueued for later processing.
    def poll
      poller.poll(skip_delete: true) do |message|
        poller.delete_message(message)

        yield(message)
      end
    end

    private

    def poller
      @poller ||= Aws::SQS::QueuePoller.new(queue_url, client: client)
    end

  end
end
