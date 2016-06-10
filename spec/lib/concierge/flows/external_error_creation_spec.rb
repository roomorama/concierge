require "spec_helper"

RSpec.describe Concierge::Flows::ExternalErrorCreation do
  let(:parameters) {
    {
      operation:   "quote",
      supplier:    "SupplierA",
      code:        "http_error",
      context:     { type: "network_failure" },
      message:     "Network Failure",
      happened_at: Time.now
    }
  }

  describe "#perform" do
    subject { described_class.new(parameters) }

    [:operation, :supplier, :code, :context, :message, :happened_at].each do |required_attr|
      it "is a no-op in case parameter #{required_attr} is not given" do
        parameters.delete(required_attr)

        expect {
          subject.perform
        }.not_to change { ExternalErrorRepository.count }
      end

      it "is a no-op if the operation is not allowed" do
        parameters[:operation] = "invalid_operation"

        expect {
          subject.perform
        }.not_to change { ExternalErrorRepository.count }
      end

      it "saves an external error to the database in case all parameters are valid" do
        expect {
          subject.perform
        }.to change { ExternalErrorRepository.count }.by(1)
      end

      it "does not fail with a hard error in case of a database failure" do
        allow(ExternalErrorRepository).to receive(:create) { raise Hanami::Model::UniqueConstraintViolationError }

        expect {
          subject.perform
        }.not_to raise_error
      end
    end
  end
end
