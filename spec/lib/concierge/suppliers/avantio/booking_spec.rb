require "spec_helper"

RSpec.describe Avantio::Booking do
  include Support::Fixtures

  let(:credentials) do
    double(username: 'Foo', password: '123')
  end
  let(:customer) do
    {
      first_name: 'John',
      last_name:  'Butler',
      email:      'john@email.com',
      phone:      '+3 5486 4560',
      address:    'Long Island 1245'
    }
  end

  let(:params) do
    API::Controllers::Params::Booking.new(
      property_id: '38180',
      check_in:    '2016-05-01',
      check_out:   '2016-05-12',
      guests:      3,
      subtotal:    3000.0,
      customer:    customer
    )
  end

  subject { described_class.new(credentials) }

  describe '#book' do
    it 'fails when is_available request fails' do
      allow_any_instance_of(Avantio::Commands::IsAvailableFetcher).to receive(:call) { Result.error(:error) }

      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :error
    end

    it 'fails when set booking request fails' do
      allow_any_instance_of(Avantio::Commands::IsAvailableFetcher).to receive(:call) { Result.new(true) }
      allow_any_instance_of(Avantio::Commands::SetBooking).to receive(:call) { Result.error(:error) }

      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :error
    end

    it 'returns unavailable error if accommodation is unavailable' do
      allow_any_instance_of(Avantio::Commands::IsAvailableFetcher).to receive(:call) { Result.new(false) }
      expect_any_instance_of(Avantio::Commands::SetBooking).to_not receive(:call)
      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :unavailable_accommodation
      expect(result.error.data).to eq 'The property user tried to book is unavailable for given period'
    end

    it 'returns result of SetBooking command' do

      allow_any_instance_of(Avantio::Commands::IsAvailableFetcher).to receive(:call) { Result.new(true) }
      allow_any_instance_of(Avantio::Commands::SetBooking).to receive(:call) do
        Result.new(double(id: 42))
      end
      result = subject.book(params)

      expect(result.value.id).to eq(42)
    end
  end
end