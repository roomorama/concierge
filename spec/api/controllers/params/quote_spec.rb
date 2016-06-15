require "spec_helper"

RSpec.describe API::Controllers::Params::Quote do
  let(:params) {
    { property_id: "A123", check_in: "2015-03-22", check_out: "2015-03-25", guests: 2 }
  }

  subject { described_class.new(params) }

  describe "#stay_length" do
    it "returns the stay length inferred from the parameters" do
      expect(subject.stay_length).to eq 3
    end
  end
end
