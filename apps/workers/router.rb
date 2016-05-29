require "invaldkfjsdlkjf"
module Workers

  class Router
    attr_reader :host

    def initialize(host)
      @host = host
    end

    def dispatch(property)
      existing = concierge_property_for(property)

      if existing
        diff = calculate_diff(existing, property)

        unless diff.empty?
          operation = Roomorama::Client::Operations.diff(diff)
        end
      else
        operation = publish_op(property)
      end

      enqueue(operation) if operation
    end

    private

    def concierge_property_for(property)
      PropertyRepository.from_host(host).identified_by(property.identifier)
    end

    def calculate_diff(existing, new)
      original = Roomorama::Property.load(existing.data)
      PropertyComparison.new(original, new).extract_diff
    end

    def publish_op(property)
      Roomorama::Client::Operations.publish(property)
    end

    def enqueue(operation)
      # next chapter
    end

  end
end
