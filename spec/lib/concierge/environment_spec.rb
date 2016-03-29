require "spec_helper"

RSpec.describe Concierge::Environment do
  let(:path) { Hanami.root.join("spec", "fixtures", "environment.yml").to_s }

  subject { described_class.new(path) }

  before do
    ENV["VARIABLE_A"] = "A"
    ENV["VARIABLE_B"] = "B"
  end

  after do
    ENV.delete("VARIABLE_A")
    ENV.delete("VARIABLE_B")
  end

  describe "#verify!" do
    it "is successful when all required variables are defined" do
      expect(subject.verify!).to be
    end

    it "fails if one variable is not defined" do
      ENV.delete("VARIABLE_A")
      expect {
        subject.verify!
      }.to raise_error Concierge::Environment::UndefinedVariableError
    end

    it "fails if one variable is empty" do
      ENV["VARIABLE_A"] = ""
      expect {
        subject.verify!
      }.to raise_error Concierge::Environment::UndefinedVariableError
    end
  end
end
