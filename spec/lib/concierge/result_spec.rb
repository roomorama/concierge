require "spec_helper"

RSpec.describe Result do
  let(:result) { 42 }

  subject { described_class.new(result) }

  describe ".error" do
    it "creates a new Result instance with the error information given" do
      subject = described_class.error(:failed, "failed to perform operation")

      expect(subject).to be_a Result
      expect(subject.error.code).to eq :failed
      expect(subject.error.message).to eq "failed to perform operation"
    end
  end

  describe "#error" do
    it "is able to store an error associated with an operation" do
      subject.error.code = :invalid_operation
      subject.error.message = "Tried to perform invalid operation"

      expect(subject.error.code).to eq :invalid_operation
      expect(subject.error.message).to eq "Tried to perform invalid operation"
    end
  end

  describe "#success?" do
    it "is successful if there is no error associated with the result" do
      expect(subject).to be_success
    end

    it "is not successful if there is an error associated with the result" do
      subject.error.code = :invalid_operation
      expect(subject).not_to be_success
    end
  end

  describe "#value" do
    it "returns the wrapped result if successful" do
      expect(subject.value).to eq 42
    end

    it "is nil if the operation was not successful" do
      subject.error.code = :invalid_operation
      expect(subject.value).to be_nil
    end
  end
end
