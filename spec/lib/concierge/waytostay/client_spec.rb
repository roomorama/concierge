require 'spec_helper'
require_relative '../shared/suppliers/client_spec'

RSpec.describe Waytostay::Client do
  include Support::Fixtures

  before do
    Concierge::Cache.new(namespace:"oauth2").fetch(supplier_client.credentials[:client_id]) do
      Result.new "{\"token_type\":\"BEARER\",\"scope\":null,\"access_token\":\"test_token\",\"refresh_token\":null,\"expires_at\":1465467451}"
    end
  end
  let(:supplier_client) { described_class.new }
  let(:params) {
    { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 }
  }
  let(:success_response) { read_fixture('waytostay/bookings/quote.json') }
  let(:fail_response) { read_fixture('waytostay/invalid_request.json') }

  describe '#quote' do
    subject { supplier_client.quote(params) }
    it_behaves_like "supplier quote method" do
      let(:test) { "world" }
      let(:quote_url) { supplier_client.credentials[:url] + described_class::ENDPOINTS[:quote] }
      let(:stub_successful_quote) { lambda {
        supplier_client.oauth2_client.oauth_client.connection =
          stub_call(:post,
                    quote_url) {
            [200, {}, success_response]
          }
      }}
    end
  end
end

