require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"
require_relative "../shared/kigo_price_quotation"

RSpec.describe API::Controllers::Kigo::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Factories

  let!(:supplier) { create_supplier(name: Kigo::Client::SUPPLIER_NAME) }
  let!(:host) { create_host(fee_percentage: 7.0, supplier_id: supplier.id) }
  let!(:property) { create_property(identifier: "567", host_id: host.id) }

  let(:params) {
    { property_id: property.identifier, check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }
  let(:endpoint) { "https://www.kigoapis.com/channels/v1/computePricing" }

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    let(:supplier_name) { "Kigo" }

    def provoke_failure!
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      Struct.new(:code).new("connection_timeout")
    end
  end

  describe "#call" do
    it_behaves_like "Kigo price quotation"
  end

end
