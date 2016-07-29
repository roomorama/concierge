require "spec_helper"
require_relative "../shared/multi_unit_quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::Woori::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

  it_behaves_like "performing multi unit parameter validations",
    controller_generator: -> { described_class.new }

  it_behaves_like "external error reporting" do
    let(:params) do
      {
        property_id: "321",
        unit_id: "123",
        check_in: "2016-03-22",
        check_out: "2016-03-25",
        guests: 2
      }
    end
    let(:supplier_name) { "Woori" }
    let(:url) { "http://my.test/available" }

    def provoke_failure!
      stub_call(:get, url) { raise Faraday::TimeoutError }
      Struct.new(:code).new("connection_timeout")
    end
  end

end
