require 'spec_helper'

RSpec.describe AtLeisure::Mappers::Calendar do
  include Support::Fixtures

  let(:property_id) { 'XX-1234-01' }
  let(:today) { Date.new(2016, 7, 14) }

  subject { described_class.new }

  before do
    allow(Date).to receive(:today).and_return(today)
  end

  describe '#build' do
    it 'returns roomorama calendar' do
      availabilities = {
        'HouseCode' => property_id,
        'AvailabilityPeriodV1' => [
          {
            'ArrivalDate' => '2016-08-31',
            'Price' => 960,
            'DepartureDate' => '2016-09-24',
            'OnRequest' => 'No'
          }
        ]
      }

      calendar = subject.build(availabilities).value

      expect { calendar.validate! }.to_not raise_error
      expect(calendar).to be_a(Roomorama::Calendar)
      expect(calendar.identifier).to eq(property_id)
    end

    it 'returns unavailable entry for on request stays' do
      availabilities = {
        'HouseCode' => property_id,
        'AvailabilityPeriodV1' => [
          {
            'ArrivalDate' => '2016-08-31',
            'Price' => 961,
            'DepartureDate' => '2016-09-24',
            'OnRequest' => 'Yes'
          },
          {
            'ArrivalDate' => '2016-09-26',
            'Price' => 962,
            'DepartureDate' => '2016-09-30',
            'OnRequest' => 'No'
          }
        ]
      }

      calendar = subject.build(availabilities).value
      expect { calendar.validate! }.to_not raise_error

      entry = calendar.entries.detect { |e| e.date == Date.new(2016, 9, 11)}
      expect(entry.available).to be_falsey
    end

    it 'correctly fills checkin/checkout allowed' do
      availabilities = {
        'HouseCode' => property_id,
        'AvailabilityPeriodV1' => [
          {
            'ArrivalDate' => '2016-08-31',
            'Price' => 960,
            'DepartureDate' => '2016-09-24',
            'OnRequest' => 'No'
          }
        ]
      }

      calendar = subject.build(availabilities).value
      expect { calendar.validate! }.to_not raise_error

      start_entry = calendar.entries.detect { |e| e.date == Date.new(2016, 8, 31)}
      expect(start_entry.available).to be_truthy
      expect(start_entry.checkin_allowed).to be_truthy
      expect(start_entry.checkout_allowed).to be_falsey

      middle_entry = calendar.entries.detect { |e| e.date == Date.new(2016, 9, 11)}
      expect(middle_entry.available).to be_truthy
      expect(middle_entry.checkin_allowed).to be_falsey
      expect(middle_entry.checkout_allowed).to be_falsey

      end_entry = calendar.entries.detect { |e| e.date == Date.new(2016, 9, 24)}
      expect(end_entry.available).to be_truthy
      expect(end_entry.checkin_allowed).to be_falsey
      expect(end_entry.checkout_allowed).to be_truthy
    end

    it 'returns unavailable entry for dates outside of availabilities' do
      availabilities = {
        'HouseCode' => property_id,
        'AvailabilityPeriodV1' => [
          {
            'ArrivalDate' => '2016-08-31',
            'Price' => 960,
            'DepartureDate' => '2016-09-24',
            'OnRequest' => 'No'
          }
        ]
      }

      calendar = subject.build(availabilities).value
      expect { calendar.validate! }.to_not raise_error

      entry = calendar.entries.detect { |e| e.date == Date.new(2016, 7, 20)}
      expect(entry.available).to be_falsey
    end

    it 'calculates nigthly rate' do
      availabilities = {
        'HouseCode' => property_id,
        'AvailabilityPeriodV1' => [
          {
            'ArrivalDate' => '2016-09-01',
            'Price' => 960,
            'DepartureDate' => '2016-09-13',
            'OnRequest' => 'No'
          },
          {
            'ArrivalDate' => '2016-09-01',
            'Price' => 1500,
            'DepartureDate' => '2016-09-26',
            'OnRequest' => 'No'
          }
        ]
      }

      calendar = subject.build(availabilities).value
      expect { calendar.validate! }.to_not raise_error

      entry = calendar.entries.detect { |e| e.date == Date.new(2016, 9, 11)}
      expect(entry.nightly_rate).to eq(60.0)
    end


    it 'returns empty calendar for empty availabilities' do
      availabilities = {
        'HouseCode' => property_id,
        'AvailabilityPeriodV1' => []
      }

      calendar = subject.build(availabilities).value

      expect(calendar.entries.length).to eq(0)
    end
  end
end