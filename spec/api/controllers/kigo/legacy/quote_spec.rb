require "spec_helper"
require_relative "../../shared/quote_validations"
require_relative "../../shared/kigo_price_quotation"

RSpec.describe API::Controllers::Kigo::Legacy::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new }

  describe "#call" do
    let(:endpoint) { "https://app.kigo.net/api/ra/v1/computePricing" }
    let(:params) {
      { property_id: "567", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    }

    it_behaves_like "Kigo price quotation"
  end
end
