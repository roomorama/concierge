module Concierge::Flows
  class OverwriteCreation
    include Hanami::Validations
    include Concierge::JSON

    attribute :data_json, presence: true
    attribute :host_id,   presence: true
    attribute :property_identifier

    def perform
      @overwrite = OverwriteRepository.create overwrite
      Result.new(overwrite)
    end

    def validate
      return Result.error(:invalid_data, "Invalid format: data not in JSON format") unless valid_json?
      overwrite.validate
    end

    private

    def overwrite
      @overwrite ||= Overwrite.new(host_id: host_id,
                    property_identifier: property_identifier,
                    data: data_hash)
    end

    def data_hash
      @data_hash ||= json_decode(data_json).value
    end

    def valid_json?
      json_decode(data_json).success?
    end

  end
end
