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
end

