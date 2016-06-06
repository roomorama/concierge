module Workers

  # +Workers::Queue+
  #
  # This class is the queue used to defer jobs to a background processor worker.
  # It is a simple wrapper to the AWS SQS service.
  #
  # Operations added to the queue should be wrapped in +Workers::Queue::Element+
  # instances.
  #
  # Example
  #
  #   credentials = Concierge::Credentials.for("sqs")
  #   queue = Workers::Queue.new(credentials)
  #   operation = Workers::Queue::Element.new(operation: "sync", data: { host_id: 2 })
  #   queue.add(operation)
  class Queue

    attr_reader :credentials

    # data - credentials to access SQS.
    def initialize(data)
      @credentials = data
    end

    # element - an instance of +Workers::Queue::Element+. If the element is not
    # valid (check the +validate!+ method), this method will raise an exception.
    #
    # On success, a new message is added to the SQS queue.
    def add(element)
      element.validate!

      sqs.send_message(
        queue_url:    queue_url,
        message_body: element.serialize
      )
    end

    # wraps the logic behind polling an SQS queue by receiving each message
    # and yielding it back to the caller, which receives only the message
    # body.
    def poll
      queue_poller.poll { |message| yield message.body }
    end

    private

    def sqs
      @sqs ||= Aws::SQS::Client.new(
        region:            credentials.region,
        access_key_id:     credentials.access_key_id,
        secret_access_key: credentials.secret_access_key
      )
    end

    def queue_poller
      @queue_poller ||= Aws::SQS::QueuePoller.new(queue_url, client: sqs)
    end

    def queue_url
      @queue_url ||= sqs.get_queue_url(queue_name: credentials.queue_name).queue_url
    end

  end

end
