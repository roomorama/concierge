require "spec_helper"

RSpec.describe API::Controllers::Params::TravelDates do
  let(:check_in)  { "2016-05-22" }
  let(:check_out) { "2016-05-27" }

  subject { described_class.new(check_in, check_out) }

  it "is valid if the dates are in the correct order" do
    expect(subject).to be_valid
    expect(subject.errors).to eq []
  end

  it "is not valid if check-out is prior check-in" do
    check_out = "2016-05-21"
    subject = described_class.new(check_in, check_out)

    expect(subject).not_to be_valid
    expect(subject.errors.size).to eq 1

    error = subject.errors.first
    expect(error.attribute).to eq "check_out"
    expect(error.validation).to eq :check_out_before_check_in
  end

  it "does not validate if one of the attributes are not present" do
    subject = described_class.new(nil, check_out)
    expect(subject).to be_valid
    expect(subject.errors).to eq []

    subject = described_class.new(check_in, nil)
    expect(subject).to be_valid
    expect(subject.errors).to eq []
  end

  describe "#stay_length" do
    it "is nil if one of the dates are not given" do
    subject = described_class.new(nil, check_out)
    expect(subject.stay_length).to eq nil

    subject = described_class.new(check_in, nil)
    expect(subject.stay_length).to eq nil
    end
  end

  it "returns the number of days of the stay" do
    expect(subject.stay_length).to eq 5
  end
end
