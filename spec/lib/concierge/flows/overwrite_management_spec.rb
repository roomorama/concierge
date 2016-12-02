require 'spec_helper'
RSpec.describe Concierge::Flows::OverwriteManagement do
  include Support::Factories

  let(:host) { create_host }
  let(:attributes) { Hash[host_id: host.id, data_json: data_json, property_identifier: 'test'] }
  let(:subject) { described_class.new(attributes) }

  describe "#validate" do
    context "invalid json" do
      let(:data_json) { '"cancellation_policy" : flexible' }
      it "should return error" do
        result = subject.validate
        expect(result).to be_a Result
        expect(result).to_not be_success
        expect(result.error.data).to eq "Invalid format: data not in JSON format"
      end
    end

    context "nil data_json" do
      let(:data_json) { nil }
      it "should return error" do
        result = subject.validate
        expect(result).to be_a Result
        expect(result).to_not be_success
        expect(result.error.data).to eq "Invalid format: data not in JSON format"
      end
    end

    context "invalid cancellation_policy" do
      let(:data_json) { '{"cancellation_policy": "some_other"}' }
      it "should return error" do
        result = subject.validate
        expect(result).to be_a Result
        expect(result).to_not be_success
        expect(result.error.data).to eq "Must be valid cancellation policy"
      end
    end
  end

  describe "#create" do
    let(:data_json) { '{"cancellation_policy": "flexible"' }
    it "should create an overwrite" do
      expect { subject.create }.to change { OverwriteRepository.count }.by 1
      overwrite = OverwriteRepository.last
      expect(overwrite.property_identifier).to eq 'test'
      expect(overwrite.data.get("cancellation_policy")).to eq "flexible"
    end

    context "property_identifier is empty string" do
      let(:attributes) { Hash[host_id: host.id, data_json: data_json, property_identifier: ''] }
      it "should coerce empty string to nil" do
        expect { subject.create }.to change { OverwriteRepository.count }.by 1
        expect(OverwriteRepository.last.property_identifier).to eq nil
      end
    end
  end

  describe "#update" do
    let!(:overwrite) { create_overwrite }
    let(:attributes) { Hash[id: overwrite.id, host_id: host.id, data_json: data_json, property_identifier: 'test'] }
    let(:data_json) { '{"cancellation_policy": "no_refund"' }
    it "should update the overwrite" do
      expect { subject.update }.to_not change { OverwriteRepository.count }
      expect(OverwriteRepository.last.data.get "cancellation_policy").to eq "no_refund"
    end
  end
end
