require "spec_helper"

RSpec.describe Concierge::Environment do
  let(:global_path) { Hanami.root.join("spec", "fixtures", "environment.yml").to_s }
  let(:app_path) { Hanami.root.join("spec", "fixtures", "app_environment.yml").to_s }

  subject { described_class.new(paths: [global_path, app_path]) }

  before do
    ENV["VARIABLE_A"] = "A"
    ENV["VARIABLE_B"] = "B"
    ENV["VARIABLE_C"] = "C"
  end

  after do
    ENV.delete("VARIABLE_A")
    ENV.delete("VARIABLE_B")
    ENV.delete("VARIABLE_C")
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

    it "removes duplications between multiple sources" do
      expect(subject.send(:required_variables)).to eq ["VARIABLE_A", "VARIABLE_B", "VARIABLE_C"]
    end
  end
end
