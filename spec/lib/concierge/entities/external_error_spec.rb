require "spec_helper"

RSpec.describe ExternalError do
  include Support::Factories

  describe "#critical?" do
    context "booking" do
      let(:external_error) { create_external_error(operation: "booking") }
      it { expect(external_error.critical?).to eq true }
    end
    context "cancellation" do
      let(:external_error) { create_external_error(operation: "cancellation") }
      it { expect(external_error.critical?).to eq true }
    end
    context "quote" do
      let(:external_error) { create_external_error(operation: "quote") }
      it { expect(external_error.critical?).to eq false }
    end
  end
end

