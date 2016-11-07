require 'spec_helper'

RSpec.describe THH::Commands::Booking do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:url) { 'http://example.org' }
  let(:customer) do
    {
      first_name: 'John',
      last_name:  'Butler',
      email:      'john@email.com',
      phone:      '+3 5486 4560'
    }
  end

  let(:params) do
    API::Controllers::Params::Booking.new(
      property_id: '15',
      check_in:    '2016-12-09',
      check_out:   '2016-12-17',
      guests:      3,
      subtotal:    3000.0,
      customer:    customer
    )
  end
  let(:credentials) { double(key: 'Foo', url: url) }

  subject { described_class.new(credentials) }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        stub_call(:get, url) { raise Faraday::TimeoutError }

        result = subject.call(params)

        expect(result).not_to be_success
        expect(result.error.code).to eq :connection_timeout
        expect(result.error.data).to be_nil
      end
    end

    context 'when xml response is correct' do
      it 'returns raw property' do
        stub_with_fixture('thh/booking_response.xml')

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Concierge::SafeAccessHash
      end
    end

    context 'when xml has unexpected structure' do
      it 'returns an error if no villa status field' do
        stub_with_fixture('thh/no_villa_status_booking_response.xml')

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Booking response for params `{"property_id"=>"15", "check_in"=>"2016-12-09", "check_out"=>"2016-12-17", "guests"=>3, "subtotal"=>3000, "customer"=>{"first_name"=>"John", "last_name"=>"Butler", "email"=>"john@email.com", "phone"=>"+3 5486 4560"}}` does not contain `response.villa_status` field')
      end

      it 'returns an error if unexpected villa status' do
        stub_with_fixture('thh/unexpected_villa_status_booking_response.xml')

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Booking response for params `{"property_id"=>"15", "check_in"=>"2016-12-09", "check_out"=>"2016-12-17", "guests"=>3, "subtotal"=>3000, "customer"=>{"first_name"=>"John", "last_name"=>"Butler", "email"=>"john@email.com", "phone"=>"+3 5486 4560"}}` contains unexpected value for `response.villa_status` field: `on_request`')
      end

      it 'returns an error if no booking status field' do
        stub_with_fixture('thh/no_booking_status_booking_response.xml')

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Booking response for params `{"property_id"=>"15", "check_in"=>"2016-12-09", "check_out"=>"2016-12-17", "guests"=>3, "subtotal"=>3000, "customer"=>{"first_name"=>"John", "last_name"=>"Butler", "email"=>"john@email.com", "phone"=>"+3 5486 4560"}}` does not contain `response.booking_status` field')
      end

      it 'returns an error if unexpected booking status' do
        stub_with_fixture('thh/unexpected_booking_status_booking_response.xml')

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Booking response for params `{"property_id"=>"15", "check_in"=>"2016-12-09", "check_out"=>"2016-12-17", "guests"=>3, "subtotal"=>3000, "customer"=>{"first_name"=>"John", "last_name"=>"Butler", "email"=>"john@email.com", "phone"=>"+3 5486 4560"}}` contains unexpected value for `response.booking_status` field: `false`')
      end

      it 'returns an error if no booking id' do
        stub_with_fixture('thh/no_booking_id_booking_response.xml')

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Booking response for params `{"property_id"=>"15", "check_in"=>"2016-12-09", "check_out"=>"2016-12-17", "guests"=>3, "subtotal"=>3000, "customer"=>{"first_name"=>"John", "last_name"=>"Butler", "email"=>"john@email.com", "phone"=>"+3 5486 4560"}}` does not contain `response.booking_id` field')
      end
    end
  end

  def stub_with_fixture(name)
    response = read_fixture(name)
    stub_call(:get, url) { [200, {}, response] }
  end
end
