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
      read_fixture('ciirus/valid_is_property_available_request.xml')
    end
    let(:message) { subject.is_property_available(property_id, check_in, check_out) }

    it { expect(message).to eq valid_request}
  end

  describe '#property_rates' do
    let(:property_id) { 10 }
    let(:valid_request) do
      read_fixture('ciirus/valid_property_rates_request.xml')
    end
    let(:message) { subject.property_rates(property_id) }

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
      read_fixture('ciirus/valid_properties_request.xml')
    end
    let(:message) do
      subject.properties(filter_options, search_options, special_options,
                         arrive_date, depart_date)
    end

    it { expect(message).to eq valid_request}
  end
end