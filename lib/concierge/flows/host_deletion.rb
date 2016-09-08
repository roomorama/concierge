module Concierge::Flows
  # +Concierge::Flows::HostDeletion+
  #
  # this class responsible for removing all entities related to host and
  # calling roomorama API to deactivate host. Returns +Result+ instance
  class HostDeletion

    attr_reader :host

    def initialize(host)
      @host = host
    end

    def call
      result = deactivate_roomorama_host
      return result unless result.success?

      delete_background_workers
      delete_sync_processes
      delete_properties
      delete_host

      Result.new(:host_deleted)
    end

    private

    def deactivate_roomorama_host
      client.perform(host_disable_operation)
    end

    def delete_background_workers
      BackgroundWorkerRepository.for_host(host).each do |worker|
        BackgroundWorkerRepository.delete(worker)
      end
    end

    def delete_sync_processes
      SyncProcessRepository.for_host(host).each do |sync|
        SyncProcessRepository.delete(sync)
      end
    end

    def delete_properties
      properties  = PropertyRepository.from_host(host).all
      identifiers = properties.map(&:identifier)

      client.perform(disable_operation(identifiers))

      properties.each do |property|
        PropertyRepository.delete(property)
      end
    end

    def delete_host
      HostRepository.delete(host)
    end

    def client
      @client ||= Roomorama::Client.new(host.access_token)
    end

    def host_disable_operation
      Roomorama::Client::Operations::DisableHost.new
    end

    def disable_operation(ids)
      Roomorama::Client::Operations::Disable.new(ids)
    end
  end
end