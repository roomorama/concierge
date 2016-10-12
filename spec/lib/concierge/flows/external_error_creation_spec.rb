require "spec_helper"

RSpec.describe Concierge::Flows::ExternalErrorCreation do
  let(:parameters) {
    {
      operation:   "quote",
      supplier:    "SupplierA",
      code:        "http_error",
      description: "detailed description",
      context:     { type: "network_failure" },
      happened_at: Time.now
    }
  }

  describe "#perform" do
    subject { described_class.new(parameters) }

    [:operation, :supplier, :code, :context, :happened_at].each do |required_attr|
      it "is a no-op in case parameter #{required_attr} is not given" do
        parameters.delete(required_attr)

        expect {
          subject.perform
        }.not_to change { ExternalErrorRepository.count }
      end
    end

    it "is allows description to be not given" do
      parameters.delete(:description)

      expect {
        subject.perform
      }.to change { ExternalErrorRepository.count }
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

    it "sets truncated description if its length is more than allowed" do
      parameters[:description] = "x" * 5000

      expect {
        external_error = subject.perform
        expect(external_error.description).to eq("x" * 2000)
      }.to change { ExternalErrorRepository.count }.by(1)
    end

    it "does not fail with a hard error in case of a database failure" do
      allow(ExternalErrorRepository).to receive(:create) { raise Hanami::Model::UniqueConstraintViolationError }

      expect {
        subject.perform
      }.not_to raise_error
    end

    it "pushes error to Rollbar" do
      expect(Rollbar).to receive(:warning).with(
        "SupplierA quote http_error: detailed description", any_args
      )

      expect {
        subject.perform
      }.not_to raise_error
    end

    context "when error description is nil" do
      it "pushes error to Rollbar" do
        parameters.delete(:description)

        expect(Rollbar).to receive(:warning).with(
          "SupplierA quote http_error", any_args
        )

        expect {
          subject.perform
        }.not_to raise_error
      end
    end
  end
end
