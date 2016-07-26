require "spec_helper"
require_relative "../../shared/quote_validations"
require_relative "../../shared/external_error_reporting"
require_relative "../../shared/kigo_price_quotation"

RSpec.describe API::Controllers::Kigo::Legacy::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Factories

  let!(:host) { create_host(commission: 7.0) }
  let!(:property) { create_property(identifier: "567") }

  let(:params) {
    { property_id: property.identifier, check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }
  let(:endpoint) { "https://app.kigo.net/api/ra/v1/computePricing" }

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    let(:supplier_name) { "Kigo Legacy" }

    def provoke_failure!
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      Struct.new(:code).new("connection_timeout")
    end
  end

  describe "#call" do
    it_behaves_like "Kigo price quotation"
  end
end
