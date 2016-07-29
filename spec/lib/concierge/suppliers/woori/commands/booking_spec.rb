require "spec_helper"

RSpec.describe Woori::Commands::Booking do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Woori::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:subject) { described_class.new(credentials) }
  let(:holding_url) { "http://my.test/reservation/holding" }
  let(:confirm_url) { "http://my.test/reservation/confirm" }
  let(:reservation_params) do
    API::Controllers::Params::MultiUnitBooking.new(
      property_id: '1',
      unit_id: '9733',
      check_in: '02/02/2016',
      check_out: '03/02/2016',
      guests: 1,
      currency_code: 'EUR',
      subtotal: '123.45',
      customer: {
        first_name: 'Test',
        last_name: 'User',
        email: 'testuser@example.com',
        phone: '111-222-3333',
        display: 'Test User'
      }
    )
  end

  it "successfully creates reservation" do
    stub_data = read_fixture("woori/reservations/holding_success.json")
    stub_call(:get, holding_url) { [200, {}, stub_data] }

    stub_data = read_fixture("woori/reservations/confirm_success.json")
    stub_call(:get, confirm_url) { [200, {}, stub_data] }

    result = subject.call(reservation_params)
    expect(result.success?).to be true
    expect(result.value).to be_kind_of(Reservation)
    expect(result.value.reference_number).to eq("w_WP20160729141224FE3E")
  end
end
