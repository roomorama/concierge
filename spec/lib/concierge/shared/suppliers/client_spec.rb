# Shared example for supplier quote method
# context required:
#   quote_url:             String
#   stub_successful_quote: lambda - called before successful expectations
#   stub_unsuccessful_quote: lambda - called for each `supplier_quote_errors`, before error expectations
#   supplier_quote_errors: array[hash] each hash is passed to `stub_unsuccessful_quote` lambda before error expectations
RSpec.shared_examples "supplier quote method" do
  include Support::HTTPStubbing
  it "returns the underlying network error if any happened" do
    stub_call(:post, quote_url) { raise Faraday::TimeoutError }
    expect(subject).not_to be_successful
    expect(subject.errors[:quote]).to eq "Could not quote price with remote supplier"
  end

  context "when successful" do
    it "returns the wrapped quotation" do
      stub_successful_quote.call

      expect(subject).to be_a Quotation
      expect(subject.errors).to be_nil
      expect(subject.total > 0).to be_truthy
    end
  end

  context "when errors occur" do
    it "returns the erred quotation" do
      supplier_quote_errors.each do |error|
        stub_unsuccessful_quote.call(error)
        expect(subject).not_to be_successful
        expect(subject.errors[:quote]).to eq "Could not quote price with remote supplier"
      end
    end
  end
end

