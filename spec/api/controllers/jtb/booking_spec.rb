require 'spec_helper'
require_relative "../shared/booking_validations"


RSpec.describe API::Controllers::JTB::Booking do
  include Support::HTTPStubbing

  let(:multi_unit_params) {
    {
      property_id: "A123",
      unit_id:     "xxx",
      check_in:    "2016-03-22",
      check_out:   "2016-03-24",
      subtotal:    250,
      guests:      2,
      customer:    {
        first_name:  "Alex",
        last_name:   "Black",
        country:     "India",
        city:        "Mumbai",
        address:     "first street",
        postal_code: "123123",
        email:       "test@example.com",
        phone:       "555-55-55",
      }
    }
  }

  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new } do
    let(:params) { multi_unit_params }
  end

  it "is invalid without a unit_id" do
    multi_unit_params.delete(:unit_id)
    response = parse_response(subject.call(multi_unit_params))

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["unit_id"]).to eq ["unit_id is required"]
  end

end
