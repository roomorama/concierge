require 'spec_helper'
RSpec.describe Concierge::Flows::OverwriteCreation do
  include Support::Factories

  let(:host) { create_host }
  let(:attributes) { Hash[host_id: host.id, data_json: data_json] }
  let(:subject) { described_class.new(attributes) }

  describe "#validate" do
    describe "validating json" do
      let(:data_json) { '"cancellation_policy" : flexible' }
      it "should return error" do
        result = subject.validate
        expect(result).to be_a Result
        expect(result).to_not be_success
        expect(result.error.data).to eq "Invalid format: data not in JSON format"
      end
    end

    describe "validating cancellation_policy" do
      let(:data_json) { '{"cancellation_policy" : "some_other"}' }
      it "should return error" do
        result = subject.validate
        expect(result).to be_a Result
        expect(result).to_not be_success
        expect(result.error.data).to eq "Must be valid cancellation policy"
      end
    end
  end
end
