require "spec_helper"

RSpec.describe Web::Support::Formatters::Number do

  describe "#present" do
    it "does not change numbers shorter than 1,000" do
      expect(subject.present(281)).to eq "281"
    end

    it "works in the 1k < n < 10k range" do
      expect(subject.present(1472)).to eq "1,472"
    end

    it "works in the 10k < n < 100k range" do
      expect(subject.present(17472)).to eq "17,472"
    end

    it "works in the 100k < n < 1M range" do
      expect(subject.present(172472)).to eq "172,472"
    end

    it "works for n > 1M" do
      expect(subject.present(3172472)).to eq "3,172,472"
    end
  end

end
