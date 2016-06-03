class Workers::OperationRunner

  # +Workers::OperationRunner::Diff+
  #
  # This class encapsulates the operation of performing changes on a property
  # (and its units) on Roomorama. It involves:
  #
  # * making an API call on Roomorama to apply the changes
  # * updating the database record on Concierge to reflect the new data.
  class Diff

    attr_reader :host, :operation

    # host      - a +Host+ instance.
    # operation - a +Roomorama::Client::Operations::Diff+ instance
    def initialize(host, operation)
      @host      = host
      @operation = operation
    end

    # property - a +Roomorama::Property+ instance representing the *new* property
    #            information.
    #
    # Returns a +Result+ that, when successful, wraps the corresponding, updated
    # +Property+ record.
    def perform(property)
      result = roomorama_client.perform(operation)
      return result unless result.success?

      Result.new(update(property))
    end

    private

    def update(property)
      entity = PropertyRepository.from_host(host).identified_by(property.identifier).first
      entity.data = format_data(property)

      PropertyRepository.update(entity)
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
