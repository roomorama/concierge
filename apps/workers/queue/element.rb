class Workers::Queue

  # +Workers::Queue::Element+
  #
  # This class is wraps the concept of one element that can be added to the workers
  # queue. All elements must follow the standard implemented by this class, so
  # that worker processing is made simple due to the unified nature of the
  # messages that are enqueued.
  #
  # Elements consist of:
  #
  # +operation+ - an identifier of the operation to be performed by the worker.
  # +data+      - a Hash of arguments necessary to carry out the operation.
  #
  # Usage
  #
  #   element = Workers::Queue::Element.new(operation: "sync", data: { host_id: 2 })
  #   element.serialize => "{ \"operation\": \"sync\", \"data\": { \"host_id\": 2 }"
  class Element

    # +Workers::Queue::Element::InvalidOperationError+
    #
    # This error might be raised upon invokation of the +Workers::Queue::Element#validate!+
    # method, if the operation given on initialization is +nil+ or not supported.
    class InvalidOperationError < StandardError
      def initialize(operation)
        super("Invalid operation given: #{operation}. Supported types: #{SUPPORTED_OPERATIONS}")
      end
    end

    include Concierge::JSON

    # defines the list of possible queue operations that can be wrapped in
    # +Element+ instances.
    SUPPORTED_OPERATIONS = %w(sync)

    attr_reader :operation, :data

    # operation - the name of the operation. A +String+
    # data      - a +Hash+ of parameters for the operation.
    def initialize(operation:, data:)
      @operation = operation
      @data      = data
    end

    # validates that the operation given is supported by the queue.
    # Raises +Workers::Queue::Element::InvalidOperationError+ in
    # case it is not; returns +true+ when successful.
    def validate!
      unless SUPPORTED_OPERATIONS.include?(operation.to_s)
        raise InvalidOperationError.new(operation.to_s)
      end

      true
    end

    # returns a JSON representation of the parameters, to be sent to the
    # queue for processing.
    def serialize
      json_encode({
        operation: operation,
        data:      data
      })
    end

  end
end
