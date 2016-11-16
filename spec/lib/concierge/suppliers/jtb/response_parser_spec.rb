require 'spec_helper'

RSpec.describe JTB::ResponseParser do
  include Support::Fixtures
  include Support::JTBClientHelper

  subject { described_class.new }

  describe '#parse_rate_plan' do
    let(:guests) { 2 }

    context 'success' do
      let(:rate_plans_ids) { ['good rate', 'small flat rate', 'abc', 'expensive_rate'] }
      let(:success_response) do
        build_quote_response(
          [
            availability(price: '2000', date: '2016-10-10', status: 'OK', occupancy: 2, rate_plan_id: 'good rate'),
            availability(price: '2100', date: '2016-10-11', status: 'OK', occupancy: 2, rate_plan_id: 'good rate'),
            availability(price: '1000', date: '2016-10-10', status: 'OK', occupancy: 2, rate_plan_id: 'another room'),
            availability(price: '1100', date: '2016-10-11', status: 'OK', occupancy: 2, rate_plan_id: 'another room'),
            availability(price: '1000', date: '2016-10-10', status: 'OK', occupancy: 1, rate_plan_id: 'small flat rate'),
            availability(price: '1100', date: '2016-10-11', status: 'OK', occupancy: 1, rate_plan_id: 'small flat rate'),
            availability(price: '1000', date: '2016-10-10', status: 'UC', occupancy: 2, rate_plan_id: 'abc'),
            availability(price: '1100', date: '2016-10-11', status: 'UC', occupancy: 2, rate_plan_id: 'abc'),
            availability(price: '4000', date: '2016-10-10', status: 'OK', occupancy: 2, rate_plan_id: 'expensive_rate'),
            availability(price: '4100', date: '2016-10-11', status: 'OK', occupancy: 2, rate_plan_id: 'expensive_rate'),
          ]
        )
      end
      let(:result) { subject.parse_rate_plan(success_response, guests, rate_plans_ids) }

      it 'is successful result' do
        expect(result).to be_a Result
        expect(result).to be_success
      end

      it 'has quotation value with best rate' do
        expect(result.value).to be_a JTB::RatePlan

        rate_plan = result.value
        expect(rate_plan.total).to eq 4100
        expect(rate_plan.rate_plan).to eq 'good rate'
        expect(rate_plan.available).to be_truthy
      end

    end

    it 'fails if invalid request' do
      response = parse read_fixture('jtb/invalid_request.json')
      result = nil

      expect {
        result = subject.parse_rate_plan(response, guests, [])
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_request
      expect(result.error.data).to eq 'The response indicated errors while processing the request. Check the `errors` field.'

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "generic_message"
    end

    it 'fails if unit not found' do
      response = parse read_fixture('jtb/unit_not_found.json')
      result   = subject.parse_rate_plan(response, guests, [])
      expect(result).not_to be_success
      expect(result.error.code).to eq :unit_not_found
      expect(result.error.data).to eq 'The response indicated errors while processing the request. Check the `errors` field.'
    end

    it 'recognises the response with single rate plan response' do
      response = parse(read_fixture("jtb/single_rate_plan_response.json"))
      result   = subject.parse_rate_plan(response, guests, ['TYOHKPT00STD1TWN'])

      expect(result).to be_success
      expect(result.value).to be_a JTB::RatePlan

      rate_plan = result.value
      expect(rate_plan.total).to eq 20700
      expect(rate_plan.rate_plan).to eq 'TYOHKPT00STD1TWN'
      expect(rate_plan.available).to be_truthy
      expect(rate_plan.occupancy).to eq 2
    end

    it 'fails if ga_hotel_avail_rs field not found' do
      response = parse read_fixture('jtb/no_ga_hotel_avail_rs_field.json')
      result   = subject.parse_rate_plan(response, guests, [])
      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq 'Expected field `ga_hotel_avail_rs` to be defined, but it was not.'
    end
  end

  describe '#parse_booking' do

    it 'fails if ga_hotel_res_rs field not found' do
      response = parse read_fixture('jtb/no_ga_hotel_res_rs_field.json')
      result   = subject.parse_booking(response)
      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq 'Expected field `ga_hotel_res_rs` to be defined, but it was not.'
    end

    it 'fails if invalid request' do
      response = parse read_fixture('jtb/invalid_booking_request.json')
      result = nil

      expect {
        result = subject.parse_booking(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_request
      expect(result.error.data).to eq 'The response indicated errors while processing the request. Check the `errors` field.'

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "generic_message"
    end

    it 'fails if hotel_reservation field not found' do
      response = parse read_fixture('jtb/no_hotel_reservation_field.json')
      result   = subject.parse_booking(response)
      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq 'Expected field `ga_hotel_res_rs.hotel_reservations.hotel_reservation` to be defined, but it was not.'
    end

    it 'fails if booking status is not "OK"' do
      response = parse read_fixture('jtb/unsuccessful_booking_status.json')
      result   = subject.parse_booking(response)
      expect(result).not_to be_success
      expect(result.error.code).to eq :fail_booking
      expect(result.error.data).to eq 'JTB indicated the booking not to have been performed successfully.' +
                                        ' The `@res_status` field was supposed to be equal to `OK`, but it was not.'
    end

    it 'returns reservation id' do
      response = parse read_fixture('jtb/success_booking.json')
      result   = subject.parse_booking(response)
      expect(result).to be_success
      expect(result.value).to eq '123456'
    end
  end

  describe '#parse_cancel' do
    it 'fails if ga_cancel_rs field not found' do
      response = parse read_fixture('jtb/no_ga_cancel_rs_field.json')
      result   = subject.parse_cancel(response)
      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq 'Expected field `ga_cancel_rs` to be defined, but it was not.'
    end

    it 'fails if invalid request' do
      response = parse read_fixture('jtb/invalid_cancel_request.json')
      result = nil

      expect {
        result = subject.parse_cancel(response)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :request_error
      expect(result.error.data).to eq 'The response indicated errors while processing the request. Check the `errors` field.'

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "generic_message"
    end

    it 'fails if cancel status is not success' do
      response = parse read_fixture('jtb/unsuccessful_cancel_status.json')
      result   = subject.parse_cancel(response)
      expect(result).not_to be_success
      expect(result.error.code).to eq :fail_cancel
      expect(result.error.data).to eq 'JTB indicated the cancel not to have been performed successfully.' +
                                        ' The `@status` field was supposed to be equal to `XL`, but it was not.'
    end

    it 'returns success result' do
      response = parse read_fixture('jtb/success_cancel.json')
      result   = subject.parse_cancel(response)
      expect(result).to be_success
      expect(result.value).to eq true
    end
  end

  private

  def parse(response)
    Yajl::Parser.parse(response, symbolize_keys: true)
  end
end
