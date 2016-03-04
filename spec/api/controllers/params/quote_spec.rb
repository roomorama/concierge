require "spec_helper"

RSpec.describe API::Controllers::Params::Quote do
  let(:params) {
    { property_id: "A123", check_in: "2015-03-22", check_out: "2015-03-25", guests: 2 }
  }

  subject { described_class.new(params) }

  describe "#check_in_date" do
    it "returns the Date representation of the check-in parameter" do
      expect(subject.check_in_date).to be_kind_of Date
    end

    it "returns the argument given if not a valid date" do
      params[:check_in] = "invalid-date"
      expect(subject.check_in_date).to be_nil
    end
  end

  describe "#check_out_date" do
    it "returns the Date representation of the check-in parameter" do
      expect(subject.check_out_date).to be_kind_of Date
    end

    it "returns the argument given if not a valid date" do
      params[:check_out] = "invalid-date"
      expect(subject.check_out_date).to be_nil
    end
  end

  describe "#stay_length" do
    it "returns the stay length inferred from the parameters" do
      expect(subject.stay_length).to eq 3
    end
  end
end
