require "spec_helper"

RSpec.describe API::Controllers::Params::DateComparison do
  let(:check_in)  { "2016-05-22" }
  let(:check_out) { "2016-05-27" }

  subject { described_class.new(check_in: check_in, check_out: check_out) }

  it "raises an error if the parameter does not contains two elements" do
    expect {
      described_class.new(check_in: check_in)
    }.to raise_error API::Controllers::Params::DateComparison::InvalidDatesError

    expect {
      described_class.new(check_in: check_in, check_out: check_out, ghost: "boo")
    }.to raise_error API::Controllers::Params::DateComparison::InvalidDatesError
  end

  it "is valid if the dates are in the correct order" do
    expect(subject).to be_valid
    expect(subject.errors).to eq []
  end

  it "is not valid if check-out is prior check-in" do
    check_out = "2016-05-21"
    subject = described_class.new(check_in: check_in, check_out: check_out)

    expect(subject).not_to be_valid
    expect(subject.errors.size).to eq 1

    error = subject.errors.first
    expect(error.attribute).to eq "check_out"
    expect(error.validation).to eq :check_out_before_check_in
  end

  it "does not validate if one of the attributes are not present" do
    subject = described_class.new(check_in: nil, check_out: check_out)
    expect(subject).to be_valid
    expect(subject.errors).to eq []

    subject = described_class.new(check_in: check_in, check_out: nil)
    expect(subject).to be_valid
    expect(subject.errors).to eq []
  end

  describe "#duration" do
    it "is nil if one of the dates are not given" do
      subject = described_class.new(check_in: nil, check_out: check_out)
      expect(subject.duration).to eq nil

      subject = described_class.new(check_in: check_in, check_out: nil)
      expect(subject.duration).to eq nil
    end

    it "returns the number of days of the stay" do
      expect(subject.duration).to eq 5
    end
  end
end
