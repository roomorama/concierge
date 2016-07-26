require "spec_helper"

RSpec.describe Woori::Commands::QuotationFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:subject) { described_class.new(credentials) }
  let(:url) { "http://my.test/available" }
  let(:quotation_params) do
    {
      property_id: 'w_w0511001',
      unit_id: 'w_w0511001_R07',
      check_in: "2015-02-26",
      check_out: "2015-02-28",
      guests: 2
    }
  end

  it "performs successful request returning Quotation object" do
    stub_data = read_fixture("woori/quotations/success.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.call(quotation_params)

    expect(result).to be_kind_of(Result)
    expect(result).to be_success

    quotation = result.value
    expect(quotation).to be_kind_of(Quotation)
    expect(quotation.total).to eq(280000.0)
    expect(quotation.currency).to eq('KRW')
    expect(quotation.available).to be true
  end
end
