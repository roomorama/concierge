require 'spec_helper'

RSpec.describe Avantio::XMLBuilder do
  include Support::Fixtures

  let(:credentials) { double(username: 'Foo', password: '123') }
  let(:property_id) { Avantio::PropertyId.from_avantio_ids('55720', '1210075202', 'itsalojamientos')}

  subject { described_class.new(credentials) }

  describe '#booking_price' do
    let(:valid_request) do
      read_fixture('avantio/booking_price_request.xml')
    end
    let(:message) { subject.booking_price(property_id, 1, Date.new(2016, 10, 3), Date.new(2016, 10, 20)) }

    it { expect(message).to eq valid_request}
  end

  describe '#is_available' do
    let(:valid_request) do
      read_fixture('avantio/is_available_request.xml')
    end
    let(:message) { subject.is_available(property_id, 1, Date.new(2016, 10, 3), Date.new(2016, 10, 20)) }

    it { expect(message).to eq valid_request}
  end

  describe '#set_booking' do
    let(:valid_request) do
      read_fixture('avantio/set_booking_request.xml')
    end
    let(:customer) do
      {
        first_name: 'John',
        last_name: 'Buttler',
        email: 'avg@mail.com',
        address: 'Long bay, 43',
        phone: '+7 837 0953 32 34'
      }
    end
    let(:message) { subject.set_booking(property_id, 1, Date.new(2016, 10, 3), Date.new(2016, 10, 20), customer, true) }

    it { expect(message).to eq valid_request}
  end
end