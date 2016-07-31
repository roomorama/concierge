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
    holding_json = read_fixture("woori/reservations/holding_success.json")
    stub_call(:get, holding_url) { [200, {}, holding_json] }

    confirm_json = read_fixture("woori/reservations/confirm_success.json")
    stub_call(:get, confirm_url) { [200, {}, confirm_json] }

    result = subject.call(reservation_params)
    expect(result.success?).to be true
    expect(result.value).to be_kind_of(Reservation)
    expect(result.value.reference_number).to eq("w_WP20160729141224FE3E")
  end

  it "creates reservation record in repository" do
    holding_json = read_fixture("woori/reservations/holding_success.json")
    stub_call(:get, holding_url) { [200, {}, holding_json] }

    confirm_json = read_fixture("woori/reservations/confirm_success.json")
    stub_call(:get, confirm_url) { [200, {}, confirm_json] }

    subject.call(reservation_params)

    reservation = ReservationRepository.first
    expect(reservation.reference_number).to eq('w_WP20160729141224FE3E')
  end

  it "fails when holding request gets a message that unit is already booked" do
    holding_json = read_fixture("woori/reservations/holding_already_booked_error.json")
    stub_call(:get, holding_url) { [400, {}, holding_json] }

    result = subject.call(reservation_params)
    expect(result.success?).to be false
    expect(result.error.code).to eq(:http_status_400)
  end

  it "fails when holding request gets invalid JSON response" do
    holding_json = read_fixture("woori/bad_response.json")
    stub_call(:get, holding_url) { [200, {}, holding_json] }

    result = subject.call(reservation_params)

    expect(result.success?).to be false
    expect(result.error.code).to eq(:invalid_json_representation)
  end

  it "fails when holding request times out" do
    stub_call(:get, holding_url) { raise Faraday::TimeoutError }

    result = subject.call(reservation_params)

    expect(result).not_to be_success
    expect(last_context_event[:message]).to eq("timeout")
    expect(result.error.code).to eq :connection_timeout
  end

  it "fails when confirm request was performed when unit was already booked" do
    holding_json = read_fixture("woori/reservations/holding_success.json")
    stub_call(:get, holding_url) { [200, {}, holding_json] }

    confirm_json = read_fixture("woori/reservations/confirm_already_booked_error.json")
    stub_call(:get, confirm_url) { [400, {}, confirm_json] }

    result = subject.call(reservation_params)
    expect(result).not_to be_success
    expect(result.error.code).to eq(:http_status_400)
  end

  it "fails when confirm request gets invalid JSON response" do
    holding_json = read_fixture("woori/reservations/holding_success.json")
    stub_call(:get, holding_url) { [200, {}, holding_json] }

    confirm_json = read_fixture("woori/bad_response.json")
    stub_call(:get, confirm_url) { [200, {}, confirm_json] }

    result = subject.call(reservation_params)

    expect(result.success?).to be false
    expect(result.error.code).to eq(:invalid_json_representation)
  end

  it "fails when confirm request times out" do
    holding_json = read_fixture("woori/reservations/holding_success.json")
    stub_call(:get, holding_url) { [200, {}, holding_json] }
    stub_call(:get, confirm_url) { raise Faraday::TimeoutError }

    result = subject.call(reservation_params)

    expect(result).not_to be_success
    expect(last_context_event[:message]).to eq("timeout")
    expect(result.error.code).to eq :connection_timeout
  end
end
