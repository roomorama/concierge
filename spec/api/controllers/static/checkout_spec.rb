require "spec_helper"

RSpec.describe API::Controllers::Static::Checkout do
  include Support::HTTPStubbing

  let(:params) {
    { property_id: "48327", check_in: "2016-12-17", check_out: "2016-12-26", guests: 2 }
  }

  it "is successful" do
    response = parse_response(subject.call(params))

    expect(response.status).to eq 200
    expect(response.headers["Content-Type"]).to eq "application/json; charset=utf-8"
    expect(response.body).to eq({ "status" => "ok" })
  end
end
