require "spec_helper"

RSpec.describe Kigo::Price do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { double(subscription_key: "32933") }
  let(:params) {
    { property_id: "321", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }

  subject { described_class.new(credentials) }

  RSpec.shared_examples "handling errors" do
    it "returns the underlying network error if any happened" do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end
  end

  describe "#quote" do
    let(:endpoint) { "https://www.kigoapis.com/channels/v1/computePricing" }

    it_behaves_like "handling errors"
  end
end
