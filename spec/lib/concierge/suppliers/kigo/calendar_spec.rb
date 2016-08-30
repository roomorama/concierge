require 'spec_helper'

RSpec.describe Kigo::Calendar do
  include Support::Fixtures
  include Support::Factories

  let(:property) { create_property }
  let(:today) { Date.today }

  subject { described_class.new(property) }

  describe '#perform' do
    let(:pricing) { JSON.parse(read_fixture('kigo/pricing_setup.json')) }

    context 'availabilities' do
      let(:availabilities) { JSON.parse(read_fixture('kigo/availabilities.json'))['AVAILABILITY'] }

      let(:availability) {
        { 'DATE' => today.to_s, 'AVAILABLE_UNITS' => 1, 'MAX_LOS' => 1 }
      }
      let(:unavailable_availability) {
        { 'DATE' => (today + 1).to_s, 'AVAILABLE_UNITS' => 0, 'MAX_LOS' => 1 }
      }

      it 'returns calendar with processed entries' do

        result = subject.perform(pricing, availabilities: availabilities)

        expect(result).to be_success

        calendar = result.value
        expect(calendar.identifier).to eq property.identifier
        expect(calendar.entries.size).to eq 368

        entry = calendar.entries.first

        expect(entry.nightly_rate).to eq 23.46
        expect(entry.available).to eq true
        expect(entry.checkin_allowed).to eq true
        expect(entry.checkout_allowed).to eq true
      end

      it 'returns calendar with unavailable dates' do
        availabilities.concat([availability, unavailable_availability])
        result = subject.perform(nil, availabilities: availabilities)

        expect(result).to be_success

        calendar          = result.value
        available_entry   = calendar.entries.find { |entry| entry.date.to_s == availability['DATE'] }
        unavailable_entry = calendar.entries.find { |entry| entry.date.to_s == unavailable_availability['DATE'] }

        expect(available_entry.available).to eq true
        expect(unavailable_entry.available).to eq false
      end
    end

    context 'reservations' do
      let(:reservation) {
        {
          'RES_CHECK_IN'  => "#{today} 14:00",
          'RES_CHECK_OUT' => "#{today + 1} 11:00"
        }
      }

      it 'returns calendar with reserved dates' do
        result = subject.perform(pricing, reservations: [reservation])

        expect(result).to be_success

        calendar = result.value
        entry    = calendar.entries.first

        expect(entry.available).to eq false
      end
    end

  end
end