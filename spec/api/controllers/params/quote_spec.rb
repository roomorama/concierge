require "spec_helper"

RSpec.describe API::Controllers::Params::Quote do
  let(:params) {
    { property_id: "A123", check_in: "2015-03-22", check_out: "2015-03-25", guests: 2 }
  }

  subject { described_class.new(params) }

  describe "#check_in" do
    it "returns the Date representation of the check-in parameter" do
      expect(subject.check_in).to be_kind_of Date
    end

    it "returns the argument given if not a valid date" do
      params[:check_in] = "invalid-date"
      expect(subject.check_in).to eq "invalid-date"
    end
  end

  describe "#check_out" do
    it "returns the Date representation of the check-in parameter" do
      expect(subject.check_out).to be_kind_of Date
    end

    it "returns the argument given if not a valid date" do
      params[:check_out] = "invalid-date"
      expect(subject.check_out).to eq "invalid-date"
    end
  end

  describe "#stay_length" do
    it "returns the stay length inferred from the parameters" do
      expect(subject.stay_length).to eq 3
    end
  end
end
