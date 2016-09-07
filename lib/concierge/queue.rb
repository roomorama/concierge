module Concierge
  # +Concierge::Queue+
  #
  # This class is the queue used to defer jobs to a background processor worker.
  # It is a simple wrapper to the AWS SQS service.
  #
  # Operations added to the queue should be wrapped in +Concierge::Queue::Element+
  # instances.
  #
  # Example
  #
  #   credentials = Concierge::Credentials.for("sqs")
  #   queue = Concierge::Queue.new(credentials)
  #   operation = Concierge::Queue::Element.new(operation: "sync", data: { host_id: 2 })
  #   queue.add(operation)
  class Concierge::Queue

    attr_reader :credentials

    # data - credentials to access SQS.
    def initialize(data)
      @credentials = data
    end

    # element - an instance of +Concierge::Queue::Element+. If the element is not
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

    def poller
      @poller ||= Concierge::Queue::Poller.new(queue_url, sqs)
    end

    private

    def sqs
      @sqs ||= Aws::SQS::Client.new(
        region:            credentials.region,
        access_key_id:     credentials.access_key_id,
        secret_access_key: credentials.secret_access_key
      )
    end

    def queue_url
      @queue_url ||= sqs.get_queue_url(queue_name: credentials.queue_name).queue_url
    end

  end
end
