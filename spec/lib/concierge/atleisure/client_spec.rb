require "spec_helper"

RSpec.describe AtLeisure::Client do
  let(:credentials) { double(username: "roomorama", password: "atleisure-roomorama") }
  let(:params) {
    { property_id: "AT-123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }

  subject { described_class.new(credentials) }

  describe "#quote" do
    it "returns the wrapped quotation from AtLeisure::Price when successful" do
      successful_quotation = Quotation.new(total: 999)
      allow_any_instance_of(AtLeisure::Price).to receive(:quote) { Result.new(successful_quotation) }

      quote = subject.quote(params)
      expect(quote).to be_a Quotation
      expect(quote.total).to eq 999
    end

    it "returns a quotation object with a generic error message on failure" do
      failed_operation = Result.error(:something_failed, "Error")
      allow_any_instance_of(AtLeisure::Price).to receive(:quote) { failed_operation }

      quote = subject.quote(params)
      expect(quote).to be_a Quotation
      expect(quote).not_to be_successful
      expect(quote.errors).to eq({ quote: "Could not quote price with remote supplier" })
    end
  end
end
