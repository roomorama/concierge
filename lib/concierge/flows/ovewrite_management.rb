module Concierge::Flows
  class OverwriteManagement
    include Hanami::Validations
    include Concierge::JSON

    attribute :data_json, presence: true
    attribute :host_id,   presence: true
    attribute :property_identifier
    attribute :id

    def initialize(attr)
      attr.each do |key, value|
        attr[key] = nil if value.to_s.empty?
      end

      super(attr)  # calls Hanami::Validations#initialize
    end

    def create
      @overwrite = OverwriteRepository.create overwrite
      Result.new(overwrite)
    end

    def update
      @overwrite = OverwriteRepository.update overwrite
      Result.new(overwrite)
    end

    def validate
      return Result.error(:invalid_data, "Invalid format: data not in JSON format") unless valid_json?
      overwrite.validate
    end

    private

    def overwrite
      @overwrite ||= OverwriteRepository.find(id) || Overwrite.new
      @overwrite.host_id             = host_id
      @overwrite.property_identifier = property_identifier
      @overwrite.data                = data_hash
      @overwrite
    end

    def data_hash
      @data_hash ||= json_decode(data_json).value
    end

    def valid_json?
      json_decode(data_json).success? && data_hash.is_a?(Hash)
    end

  end
end
