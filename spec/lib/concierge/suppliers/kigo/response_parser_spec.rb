require "spec_helper"

RSpec.describe Kigo::ResponseParser do
  include Support::Fixtures

  let(:host) { Host.new(commission: 0) }
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
      expect(result.error.code).to eq :quote_call_failed

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

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "fails if there is no currency or total fields" do
      response = read_fixture("kigo/no_total.json")
      result   = nil

      expect {
        result = subject.compute_pricing(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response

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
      allow(subject).to receive(:host) { host }
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
    end

    it "returns nett ammount if host has a commission" do
      host.commission = 8.0
      allow(subject).to receive(:host) { host }

      response = read_fixture("kigo/success.json")
      result   = subject.compute_pricing(response)

      expect(result.value.total).to eq 570/1.08 # 527.777
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
      expect(result.error.code).to eq :booking_call_failed

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
      allow(subject).to receive(:host) { host }

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
end
