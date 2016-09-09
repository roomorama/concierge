require "spec_helper"
require_relative "../shared/booking_validations"

RSpec.describe API::Controllers::RentalsUnited::Booking do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:params) do
    {
      property_id: '588999',
      check_in: '2016-02-02',
      check_out: '2016-02-03',
      guests: 1,
      currency_code: 'EUR',
      subtotal: '123.45',
      customer: {
        first_name: 'Test',
        last_name: 'User',
        email: 'testuser@example.com'
      }
    }
  end

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:safe_params) { Concierge::SafeAccessHash.new(params) }
  let(:controller) { described_class.new }

  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new }

  it "returns success response if booking request is completed successfully" do
    stub_data = read_fixture("rentals_united/reservations/success.xml")
    stub_call(:post, credentials.url) { [200, {}, stub_data] }

    response = parse_response(controller.call(params))
    expect(response.status).to eq 200
    expect(response.body['status']).to eq('ok')
    expect(response.body['reference_number']).to eq('90377000')
    expect(response.body['property_id']).to eq('588999')
    expect(response.body['check_in']).to eq('2016-02-02')
    expect(response.body['check_out']).to eq('2016-02-03')
    expect(response.body['guests']).to eq(1)
    expect(response.body['customer']).to eq(params[:customer])
  end

  it "returns error response if booking request failed" do
    stub_data = read_fixture("rentals_united/reservations/not_available.xml")
    stub_call(:post, credentials.url) { [200, {}, stub_data] }

    response = parse_response(controller.call(params))
    expect(response.status).to eq 503
    expect(response.body['status']).to eq('error')
    expect(response["body"]["errors"]["booking"]).to eq(
      "Could not create booking with remote supplier"
    )
  end
end
