require "spec_helper"

RSpec.describe ExternalErrorRepository do
  around do |example|
    ExternalErrorRepository.transaction do
      example.run
    end
  end

  let(:external_error_attributes) {
    {
      operation:   "quote",
      supplier:    "SupplierA",
      code:        "http_error",
      message:     "Network Failure",
      happened_at: Time.now
    }
  }

  describe ".count" do
    it "is zero when there are no records in the database" do
      expect(described_class.count).to eq 0
    end

    it "increases when new records are added" do
      error = ExternalError.new(external_error_attributes)
      described_class.create(error)

      expect(described_class.count).to eq 1
    end
  end
end
