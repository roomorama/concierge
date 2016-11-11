require "spec_helper"

RSpec.describe Kigo::ResponseParser do
  include Support::Fixtures
  include Support::Factories

  let!(:host) { create_host(fee_percentage: 7) }
  let!(:property) { create_property(identifier: "123", host_id: host.id) }

  subject { described_class.new(request_params) }

  describe "#compute_pricing" do

    let(:request_params) {
      { property_id: "123", check_in: "2016-04-05", check_out: "2016-04-08", guests: 1 }
    }

    it "fails if the API response does not indicate success" do
      response = read_fixture("kigo/e_nosuch.json")
      result   = nil

      expect {
        result = subject.compute_pricing(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq "The `API_RESULT_CODE` obtained was not equal to `E_OK`. Check Kigo's API documentation for an explanation for the `API_RESULT_CODE` returned."

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "fails if the API returns an invalid JSON response" do
      result = subject.compute_pricing("invalid-json")

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it "fails without a reply field" do
      response = read_fixture("kigo/no_api_reply.json")
      result   = nil

      expect {
        result = subject.compute_pricing(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq "Response does not contain mandatory field `API_REPLY`."

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "fails if there is no total field" do
      response = read_fixture("kigo/no_total.json")
      result   = nil

      expect {
        result = subject.compute_pricing(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq "Response does not contain mandatory field `TOTAL_AMOUNT`."

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "fails if there is no currency field" do
      response = read_fixture("kigo/no_currency.json")
      result   = nil

      expect {
        result = subject.compute_pricing(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq "Response does not contain mandatory field `CURRENCY`."

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "fails if check-in date is too far" do
      response = read_fixture("kigo/check_in_too_far.json")
      result   = nil

      expect {
        result = subject.compute_pricing(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :check_in_too_far
      expect(result.error.data).to eq "Selected check-in date is too far"

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "is unavailable if the API indicates so" do
      response = read_fixture("kigo/unavailable.json")
      result   = subject.compute_pricing(response)

      expect(result).to be_success
      quotation = result.value
      expect(quotation).to be_a Quotation
      expect(quotation.available).to eq false
    end

    it "returns a quotation with the returned information on success" do
      response = read_fixture("kigo/success.json")
      result   = subject.compute_pricing(response)

      expect(result).to be_success
      quotation = result.value
      expect(quotation).to be_a Quotation
      expect(quotation.property_id).to eq "123"
      expect(quotation.check_in).to eq "2016-04-05"
      expect(quotation.check_out).to eq "2016-04-08"
      expect(quotation.guests).to eq 1
      expect(quotation.available).to eq true
      expect(quotation.currency).to eq "EUR"
      expect(quotation.total).to eq 570.0
      expect(quotation.net_rate).to eq 530.1
      expect(quotation.host_fee).to eq 39.9
      expect(quotation.host_fee_percentage).to eq 7
    end

    it "returns net ammount if host has a fee" do
      host.fee_percentage = 8.0
      HostRepository.update host
      #allow(subject).to receive(:host) { host }

      response = read_fixture("kigo/success.json")
      result   = subject.compute_pricing(response)

      expect(result.value.total).to eq 570
      expect(result.value.net_rate).to eq 524.4
    end

  end

  describe "#parse_reservation" do

    let(:request_params) {
      {
        property_id: '123',
        check_in:    '2016-03-22',
        check_out:   '2016-03-24',
        guests:      2,
        customer:    {
          first_name: 'Alex',
          last_name:  'Black',
          email:      'alex@black.com'
        }
      }
    }

    it "fails if the API response does not indicate success" do
      response = read_fixture("kigo/e_nosuch.json")
      result   = nil

      expect {
        result = subject.parse_reservation(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq "The `API_RESULT_CODE` obtained was not equal to `E_OK`. Check Kigo's API documentation for an explanation for the `API_RESULT_CODE` returned."

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "fails if the API returns an invalid JSON response" do
      result = subject.parse_reservation("invalid-json")

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it "fails without a reservation.reference_number field" do
      response = read_fixture("kigo/no_api_reply.json")
      result   = nil

      expect {
        result = subject.parse_reservation(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "fails with unavailable dates" do
      response = read_fixture("kigo/unavailable_dates.json")
      result   = subject.parse_reservation(response)

      expect(result).not_to be_success
      expect(result.error.code).to eq :unavailable_dates
    end

    it "returns a reservation with the returned information on success" do
      response = read_fixture("kigo/success_booking.json")
      result   = subject.parse_reservation(response)

      expect(result).to be_success
      reservation = result.value
      expect(reservation).to be_a Reservation
      expect(reservation.property_id).to eq "123"
      expect(reservation.check_in).to eq "2016-03-22"
      expect(reservation.check_out).to eq "2016-03-24"
      expect(reservation.guests).to eq 2
      expect(reservation.reference_number).to eq "24985"
    end
  end

  describe "#parse_cancellation" do
    let(:request_params) {
      { reference_number: 123 }
    }

    it "fails if the API response does not indicate success" do
      response = read_fixture("kigo/e_nosuch.json")
      result   = nil

      expect {
        result = subject.parse_cancellation(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :reservation_not_found

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "fails if the reservation already cancelled" do
      response = read_fixture("kigo/already_cancelled.json")
      result   = nil

      expect {
        result = subject.parse_cancellation(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :already_cancelled

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "returns result with reference number on success" do
      response = read_fixture("kigo/cancel.json")
      result = subject.parse_cancellation(response)

      expect(result).to be_success
      expect(result.value).to eq 123
    end

  end
end
