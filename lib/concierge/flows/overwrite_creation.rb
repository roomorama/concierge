module Concierge::Flows
  class OverwriteCreation
    include Hanami::Validations
    attribute :data_hash, presence: true
    attribute :host_id,   presence: true

    def perform
      overwrite = Overwrite.new(host_id: host_id,
                                data: data)
      OverwriteRepository.create overwrite
    end
  end
end
