class Concierge::Context

  # +Concierge::Context::SyncProcess+
  #
  # This class wraps the event of the start of the synchronisation process of
  # a given property, by a given host.
  #
  # Usage
  #
  #   sync_process = Concierge::Context::SyncProcess.new(
  #     host_id:    host.id,
  #     identifier: "prop1"
  #   )
  class SyncProcess

    CONTEXT_TYPE = "sync_process"

    attr_reader :worker, :host_id, :type, :identifier, :timestamp

    def initialize(worker:, host_id:, identifier:)
      @worker     = worker
      @host_id    = host_id
      @identifier = identifier
      @timestamp  = Time.now
    end

    def to_h
      {
        type:       CONTEXT_TYPE,
        worker:     worker,
        timestamp:  timestamp,
        host_id:    host_id,
        identifier: identifier
      }
    end

  end

end
