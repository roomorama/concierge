require "spec_helper"

RSpec.describe Roomorama::Diff::Image do
  subject { described_class.new("IMG321") }

  before do
    subject.caption = "Swimming Pool 2"
  end

  describe "#validate!" do
    it "is valid if all identifier and caption are present" do
      expect(subject.validate!).to be
    end

    it "is not valid if the identifier is not present" do
      subject.identifier = nil
      expect {
        subject.validate!
      }.to raise_error Roomorama::Diff::Image::ValidationError
    end

    it "is not valid if the caption is not set" do
      subject.caption = nil
      expect {
        subject.validate!
      }.to raise_error Roomorama::Diff::Image::ValidationError
    end
  end

  describe "#to_h" do
    it "serializes the diff" do
      expect(subject.to_h).to eq({
        identifier: "IMG321",
        caption:    "Swimming Pool 2"
      })
    end
  end
end
