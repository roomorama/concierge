module Concierge::Flows
  class HostDeletion

    attr_reader :host

    def initialize(host)
      @host = host
    end

    def call
      result = deactivate_roomorama_host
      return unless result.success?

      delete_background_workers
      delete_host
    end

    private

    def deactivate_roomorama_host
      client.perform(operation)
    end

    def delete_background_workers
      BackgroundWorkerRepository.for_host(host).each do |worker|
        BackgroundWorkerRepository.delete(worker)
      end
    end

    def delete_host
      HostRepository.delete(host)
    end

    def client
      @client ||= Roomorama::Client.new(host.access_token)
    end

    def operation
      Roomorama::Client::Operations::DisableHost.new
    end
  end
end