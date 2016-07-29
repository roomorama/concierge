require 'spec_helper'

RSpec.describe Ciirus::XMLBuilder do
  include Support::Fixtures

  let(:credentials) { double(username: 'Foo', password: '123') }

  subject { described_class.new(credentials) }

  describe '#is_property_available' do
    let(:property_id) { 10 }
    let(:check_in) { Date.new(2016, 6, 3) }
    let(:check_out) { Date.new(2016, 7, 2) }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_is_property_available_request.xml')
    end
    let(:message) { subject.is_property_available(property_id, check_in, check_out) }

    it { expect(message).to eq valid_request}
  end

  describe '#property_rates' do
    let(:property_id) { 10 }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_property_rates_request.xml')
    end
    let(:message) { subject.property_rates(property_id) }

    it { expect(message).to eq valid_request}
  end

  describe '#property_permissions' do
    let(:property_id) { 10 }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_property_permissions_request.xml')
    end
    let(:message) { subject.property_permissions(property_id) }

    it { expect(message).to eq valid_request}
  end

  describe '#image_list' do
    let(:property_id) { 10 }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_image_list_request.xml')
    end
    let(:message) { subject.image_list(property_id) }

    it { expect(message).to eq valid_request}
  end

  describe '#descriptions_plain_text' do
    let(:property_id) { 10 }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_descriptions_plain_text_request.xml')
    end
    let(:message) { subject.descriptions(property_id) }

    it { expect(message).to eq valid_request}
  end

  describe '#reservations' do
    let(:property_id) { 10 }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_reservations_request.xml')
    end
    let(:message) { subject.reservations(property_id) }

    it { expect(message).to eq valid_request}
  end

  describe '#cancel' do
    let(:booking_id) { 10 }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_cancel_request.xml')
    end
    let(:message) { subject.cancel(booking_id) }

    it { expect(message).to eq valid_request}
  end

  describe '#extras' do
    let(:booking_id) { 10 }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_extras_request.xml')
    end
    let(:message) { subject.extras(booking_id) }

    it { expect(message).to eq valid_request}
  end

  describe '#properties' do
    let(:property_id) { 10 }
    let(:filter_options) { Ciirus::FilterOptions.new(property_id: property_id) }
    let(:search_options) { Ciirus::SearchOptions.new(quote: true) }
    let(:special_options) { Ciirus::SpecialOptions.new }
    let(:arrive_date) { '1 May 2016' }
    let(:depart_date) { '10 May 2016' }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_properties_request.xml')
    end
    let(:message) do
      subject.properties(filter_options, search_options, special_options,
                         arrive_date, depart_date)
    end

    it { expect(message).to eq valid_request}
  end

  describe '#make_booking' do
    let(:property_id) { 10 }
    let(:guest) do
      Ciirus::BookingGuest.new('John Buttler',
                               'my@email.com',
                               'Long Island 123',
                               '+3 675 45879')
    end
    let(:arrival_date) { '1 May 2016' }
    let(:departure_date) { '10 May 2016' }
    let(:valid_request) do
      read_fixture('ciirus/requests/valid_make_booking_request.xml')
    end
    let(:message) do
      subject.make_booking(property_id, arrival_date, departure_date, guest)
    end

    it { expect(message).to eq valid_request }
  end
end