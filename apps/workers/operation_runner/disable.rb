class Workers::OperationRunner

  # +Workers::OperationRunner::Disable+
  #
  # Wraps the logic of disabling/deleting a set of properties with the given
  # identifiers on Roomorama. That involves the following steps:
  #
  # * performing an API call to Roomorama to delete the properties
  # * deleting properties from the given host with the identifiers given from
  #   the Concierge database.
  class Disable

    attr_reader :host, :operation

    # host      - a +Host+ instance.
    # operation - a +Roomorama::Client::Operations::Disable+ instance
    def initialize(host, operation)
      @host      = host
      @operation = operation
    end

    # performs an API call to delete the propreties on Roomorama. If that is
    # successful, proceeds to delete the properties on the dabase.
    #
    # Returns a +Result+ instance wrapping a single boolean value in case
    # the entire process is successful.
    def perform
      result = roomorama_client.perform(operation)
      return result unless result.success?

      delete_properties(operation.identifiers)
      Result.new(true)
    end

    private

    def delete_properties(identifiers)
      PropertyRepository.from_host(host).identified_by(identifiers).each do |property|
        PropertyRepository.delete(property)
      end
    end

    def roomorama_client
      @roomorama_client ||= Roomorama::Client.new(host.access_token)
    end

  end
end
