require "spec_helper"

RSpec.describe Roomorama::Client::Operations::Disable do
  let(:identifiers) { %w(JPN123 JPN321) }

  subject { described_class.new(identifiers) }

  describe "#endpoint" do
    it "knows the endpoint where a property can be disabled" do
      expect(subject.endpoint).to eq "/v1.0/host/disable"
    end
  end

  describe "#method" do
    it "knows the request method to be used when publishing" do
      expect(subject.request_method).to eq :put
    end
  end

  describe "#request_data" do
    it "serializes the property identifier" do
      expect(subject.request_data).to eq({ identifiers: ["JPN123", "JPN321"] })
    end
  end
end
