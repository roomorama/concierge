require "spec_helper"

RSpec.describe UseCases::ExternalErrorCreation do
  let(:parameters) {
    {
      operation:   "quote",
      supplier:    "SupplierA",
      code:        "http_error",
      message:     "Network Failure",
      happened_at: Time.now
    }
  }

  describe "#perform" do
    around do |example|
      ExternalErrorRepository.transaction do
        example.run
      end
    end

    subject { described_class.new(parameters) }

    [:operation, :supplier, :code, :message, :happened_at].each do |required_attr|
      it "is a no-op in case parameter #{required_attr} is not given" do
        parameters.delete(required_attr)

        expect {
          expect(subject.perform)
        }.not_to change { ExternalErrorRepository.count }
      end

      it "is a no-op if the operation is not allowed" do
        parameters[:operation] = "invalid_operation"

        expect {
          expect(subject.perform)
        }.not_to change { ExternalErrorRepository.count }
      end

      it "saves an external error to the database in case all parameters are valid" do
        expect {
          expect(subject.perform)
        }.to change { ExternalErrorRepository.count }.by(1)
      end
    end
  end
end
