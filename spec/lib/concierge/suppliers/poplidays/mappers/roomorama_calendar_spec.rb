require 'spec_helper'

RSpec.describe Poplidays::Mappers::RoomoramaCalendar do
  include Support::Fixtures

  let(:property_id) { '8927439190' }
  let(:today) { Date.new(2016, 7, 14) }
  let(:property_details) { {'mandatoryServicesPrice' => 25.0} }

  subject { described_class.new }

  before do
    allow(Date).to receive(:today).and_return(today)
  end

  describe '#build' do
    it 'returns roomorama calendar' do
      availabilities_hash = {
        'availabilities' => [
          {
            'arrival' => '20160831',
            'basePrice' => 960.0,
            'departure' => '20160924',
            'discountPercent' => 0.0,
            'price' => 960.0,
            'priceEnabled' => true,
            'requestOnly' => false
          }
        ]
      }

      calendar = subject.build(property_id, property_details, availabilities_hash)

      expect { calendar.validate! }.to_not raise_error
      expect(calendar).to be_a(Roomorama::Calendar)
      expect(calendar.identifier).to eq(property_id)
    end

    it 'returns unavailable entry for on request stays' do
      availabilities_hash = {
        'availabilities' => [
          {
            'arrival' => '20160831',
            'basePrice' => 960.0,
            'departure' => '20160924',
            'discountPercent' => 0.0,
            'price' => 960.0,
            'priceEnabled' => true,
            'requestOnly' => true
          },
          {
            'arrival' => '20160926',
            'basePrice' => 960.0,
            'departure' => '20160930',
            'discountPercent' => 0.0,
            'price' => 960.0,
            'priceEnabled' => true,
            'requestOnly' => false
          }
        ]
      }

      calendar = subject.build(property_id, property_details, availabilities_hash)
      expect { calendar.validate! }.to_not raise_error

      entry = calendar.entries.detect { |e| e.date == Date.new(2016, 9, 11)}
      expect(entry.available).to be_falsey
    end

    it 'returns unavailable entry for price disabled stays' do
      availabilities_hash = {
        'availabilities' => [
          {
            'arrival' => '20160831',
            'basePrice' => 960.0,
            'departure' => '20160924',
            'discountPercent' => 0.0,
            'price' => 960.0,
            'priceEnabled' => false,
            'requestOnly' => false
          },
          {
            'arrival' => '20160926',
            'basePrice' => 960.0,
            'departure' => '20160930',
            'discountPercent' => 0.0,
            'price' => 960.0,
            'priceEnabled' => true,
            'requestOnly' => false
          },
        ]
      }
      calendar = subject.build(property_id, property_details, availabilities_hash)
      expect { calendar.validate! }.to_not raise_error

      entry = calendar.entries.detect { |e| e.date == Date.new(2016, 9, 11)}
      expect(entry.available).to be_falsey
    end

    it 'correctly fills checkin/checkout allowed' do
      availabilities_hash = {
        'availabilities' => [
          {
            'arrival' => '20160831',
            'basePrice' => 960.0,
            'departure' => '20160924',
            'discountPercent' => 0.0,
            'price' => 960.0,
            'priceEnabled' => true,
            'requestOnly' => false
          }
        ]
      }

      calendar = subject.build(property_id, property_details, availabilities_hash)
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
      availabilities_hash = {
        'availabilities' => [
          {
            'arrival' => '20160831',
            'basePrice' => 960.0,
            'departure' => '20160924',
            'discountPercent' => 0.0,
            'price' => 960.0,
            'priceEnabled' => true,
            'requestOnly' => false
          }
        ]
      }

      calendar = subject.build(property_id, property_details, availabilities_hash)
      expect { calendar.validate! }.to_not raise_error

      entry = calendar.entries.detect { |e| e.date == Date.new(2016, 7, 20)}
      expect(entry.available).to be_falsey
    end

    it 'calculates nigthly rate' do
      availabilities_hash = {
        'availabilities' => [
          {
            'arrival' => '20160901',
            'basePrice' => 960.0,
            'departure' => '20160913',
            'discountPercent' => 0.0,
            'price' => 960.0,
            'priceEnabled' => true,
            'requestOnly' => false
          },
          {
            'arrival' => '20160901',
            'basePrice' => 1500.0,
            'departure' => '20160926',
            'discountPercent' => 0.0,
            'price' => 1500.0,
            'priceEnabled' => true,
            'requestOnly' => false
          }
        ]
      }

      calendar = subject.build(property_id, property_details, availabilities_hash)
      expect { calendar.validate! }.to_not raise_error

      entry = calendar.entries.detect { |e| e.date == Date.new(2016, 9, 11)}
      expect(entry.nightly_rate).to eq(61.0)
    end


    it 'returns empty calendar for empty availabilities' do
      availabilities_hash = {
        'availabilities' => []
      }

      calendar = subject.build(property_id, property_details, availabilities_hash)

      expect(calendar.entries.length).to eq(0)
    end
  end
end