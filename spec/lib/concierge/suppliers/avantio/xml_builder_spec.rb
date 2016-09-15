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

  describe '#cancel' do
    let(:valid_request) do
      read_fixture('avantio/cancel_request.xml')
    end
    let(:message) { subject.cancel('34634727') }

    it { expect(message).to eq valid_request}
  end
end