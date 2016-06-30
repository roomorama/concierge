require "spec_helper"

RSpec.describe Kigo::Client do
  let(:credentials) { double(subscription_key: "beefdead") }
  let(:params) {
    { property_id: "123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }

  subject { described_class.new(credentials) }

  describe "#quote" do
    it "returns the wrapped quotation from Kigo::Price when successful" do
      successful_quotation = Quotation.new(total: 999)
      allow_any_instance_of(Kigo::Price).to receive(:quote) { Result.new(successful_quotation) }

      quote_result = subject.quote(params)
      expect(quote_result).to be_success

      quote = quote_result.value
      expect(quote).to be_a Quotation
      expect(quote.total).to eq 999
    end

    it "returns a quotation object with a generic error message on failure" do
      failed_operation = Result.error(:something_failed)
      allow_any_instance_of(Kigo::Price).to receive(:quote) { failed_operation }

      quote_result = subject.quote(params)
      expect(quote_result).to_not be_success
      expect(quote_result.error.code).to eq :something_failed

      quote = quote_result.value
      expect(quote).to be_nil
    end
  end
end
