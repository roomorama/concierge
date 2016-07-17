module Workers

  # +Workers::Router+
  #
  # This class is responsible for determining what operation, if any, should be
  # performed for a given property that was received from a supplier.
  #
  # Example
  #   property = Roomorama::Property.new("property1")
  #   # supplier API is called and +property+ is populated
  #   host = Host.last
  #   router = Workers::Router.new(host)
  #   router.dispatch(property) # => #<Roomorama::Client::Operations::Publish...>
  #
  # In case the property is unknown to Concierge, the router will generate
  # a +publish+ operation for it, meaning it will be made available on
  # Roomorama. In case the property was previously published, the difference
  # between the property and the last known version of it is calculated, and
  # the corresponding +Roomorama::Client::Operations::Diff+ operation is
  # returned.
  class Router

    # +Workers::Router::InvalidSerializedDataError+
    #
    # This error is raised when data in Concierge's database for a given property
    # cannot be loaded back into a +Roomorama::Property+ instance.
    class InvalidSerializedDataError < StandardError
      def initialize(property)
        super("Property ##{property.id} has a `data` field that cannot be loaded.")
      end
    end

    attr_reader :host

    # host - a +Host+ instance, representing the host that owns the properties
    #        that are going to be routed.
    def initialize(host)
      @host = host
    end

    # +property+ is expected to be an instance of +Roomorama::Property+. Returns:
    #
    # - an instance of +Roomorama::Client::Operations::Publish+ if the
    #   property needs to be published
    # - an instance of +Roomorama::Client::Operations::Diff+ if the
    #   property needs to be updated
    # - +nil+ in case there are no changes from the last known version
    #   of the given property.
    def dispatch(property)
      existing = concierge_property_for(property)

      if existing
        diff = calculate_diff(existing, property)

        unless diff.empty?
          Roomorama::Client::Operations.diff(diff)
        end
      elsif !property.disabled
        publish_op(property)
      end
    end

    private

    def concierge_property_for(property)
      PropertyRepository.from_host(host).identified_by(property.identifier).first
    end

    def calculate_diff(existing, new)
      original = Roomorama::Property.load(existing.data)
      ensure_valid_data!(original, existing)

      Comparison::Property.new(original.value, new).extract_diff
    end

    def publish_op(property)
      Roomorama::Client::Operations.publish(property)
    end

    # in case the +Result+ returned from calling +Roomorama::Property.load+ with
    # data from the database results in a non-successful result, we raise a hard
    # error, since this is a scenario that should not happen. The error message
    # includes the property +id+ so that further investigation is possible.
    def ensure_valid_data!(result, property)
      unless result.success?
        raise InvalidSerializedDataError.new(property)
      end
    end

  end
end
