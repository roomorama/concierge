class Workers::OperationRunner

  # +Workers::OperationRunner::Publish+
  #
  # This class is responsible for running a publish operation. That encompasses
  # the following steps:
  #
  # * make an API call to Roomorama to publish the property
  # * persist the property on Concierge's database with the given data.
  #
  # In case the API call fails, the property should not be persisted.
  # As +Roomorama::Client+ uses +Concierge::HTTPClient+ under the hood, the
  # failure is stored in the process context and can later be analysed
  # to understand the reason of the occurrence.
  class Publish

    attr_reader :host, :operation

    # host      - a +Host+ instance.
    # operation - a +Roomorama::Client::Operations::Publish+ instance
    def initialize(host, operation)
      @host      = host
      @operation = operation
    end

    # executes the publishing action. Makes the API call and persists the property
    # in the database if successful.
    #
    # Returns a +Result+ instance that wraps the corresponding +Property+ on
    # success.
    def perform(property)
      result = roomorama_client.perform(operation)
      return result unless result.success?

      Result.new(persist(property))
    end

    private

    def persist(property)
      entity = Property.new(
        identifier: property.identifier,
        host_id:    host.id,
        data:       format_data(property)
      )

      PropertyRepository.create(entity)
    end

    # availabilities information does not need to be kept on the database,
    # since it is not incrementally updated.
    def format_data(property)
      property.to_h.tap do |attributes|
        attributes.delete(:availabilities)
      end
    end

    def roomorama_client
      @roomorama_client ||= Roomorama::Client.new(host.access_token)
    end

  end
end
