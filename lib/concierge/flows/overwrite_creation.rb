module Concierge::Flows
  class OverwriteCreation
    include Hanami::Validations
    include Concierge::JSON

    attribute :data_json, presence: true
    attribute :host_id,   presence: true


    def validate
      return Result.error(:invalid_data, "Invalid format: data not in JSON format") unless valid_json?
      return Result.error(:invalid_data, "Must be valid cancellation policy") unless valid_cancellation_policy?
      return Result.new(true)
    end

    def perform
      overwrite = Overwrite.new(host_id: host_id,
                                data: data_hash)
      overwrite = OverwriteRepository.create overwrite
      Result.new(overwrite)
    end

    private

    def valid_cancellation_policy?
      Roomorama::CancellationPolicy.all.include? data_hash["cancellation_policy"]
    end

    def valid_json?
      json_decode(data_json).success?
    end

    def data_hash
      @data_hash ||= json_decode(data_json).value
    end

  end
end
