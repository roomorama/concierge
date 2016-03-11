require "spec_helper"

RSpec.describe Poplidays::Client do
  let(:params) {
    { property_id: "439439", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }

  describe "#quote" do
    it "returns the wrapped quotation from Poplidays::Price when successful" do
      successful_quotation = Quotation.new(total: 999)
      allow_any_instance_of(Poplidays::Price).to receive(:quote) { Result.new(successful_quotation) }

      quote = subject.quote(params)
      expect(quote).to be_a Quotation
      expect(quote.total).to eq 999
    end

    it "returns a quotation object with a generic error message on failure" do
      failed_operation = Result.error(:something_failed, "Error")
      allow_any_instance_of(Poplidays::Price).to receive(:quote) { failed_operation }

      quote = subject.quote(params)
      expect(quote).to be_a Quotation
      expect(quote).not_to be_successful
      expect(quote.errors).to eq({ quote: "Could not quote price with remote supplier" })
    end
  end
end
