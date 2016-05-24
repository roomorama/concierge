require "spec_helper"

RSpec.describe Roomorama::Client::Operations::Diff do
  let(:diff) { Roomorama::Diff.new("JPN123") }

  subject { described_class.new(diff) }

  before do
    diff.title = "Studio Apartment in Paris"
  end

  describe "#initialize" do
    it "allows object creation for valid diffs" do
      expect(subject).to be
    end

    it "raises an error in case an invalid diff is passed" do
      diff.identifier = nil
      expect {
        subject
      }.to raise_error Roomorama::Diff::ValidationError
    end
  end

  describe "#endpoint" do
    it "knows the endpoint where a property can be published" do
      expect(subject.endpoint).to eq "/v1.0/host/apply"
    end
  end

  describe "#method" do
    it "knows the request method to be used when publishing" do
      expect(subject.request_method).to eq :put
    end
  end

  describe "#request_data" do
    it "calls the +to_h+ method of the underlying property" do
      expect(diff).to receive(:to_h)
      subject.request_data
    end
  end
end
