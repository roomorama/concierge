require 'spec_helper'

RSpec.describe Avantio::Entities::OccupationalRule::Season do

  describe '#checkin_allowed' do
    it 'returns true if weekdays check passed with empty monthdays' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        [],
        ['MONDAY'],
        ['10', '11'],
        ['MONDAY', 'TUESDAY']
      )
      expect(season.checkin_allowed(Date.new(2016, 9, 12))).to be true
    end

    it 'returns true if monthdays check passed with empty weekdays' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['12'],
        [],
        ['10', '11'],
        ['MONDAY', 'TUESDAY']
      )
      expect(season.checkin_allowed(Date.new(2016, 9, 12))).to be true
    end

    it 'returns true if weekdays check passed and monthdays chech passed' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['12'],
        ['MONDAY'],
        ['10', '11'],
        ['MONDAY', 'TUESDAY']
      )
      expect(season.checkin_allowed(Date.new(2016, 9, 12))).to be true
    end

    it 'returns false if at least one check fails' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['13'],
        ['MONDAY'],
        ['10', '11'],
        ['MONDAY', 'TUESDAY']
      )
      expect(season.checkin_allowed(Date.new(2016, 9, 13))).to be false

      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['11'],
        ['MONDAY'],
        ['10', '11'],
        ['MONDAY', 'TUESDAY']
      )
      expect(season.checkin_allowed(Date.new(2016, 9, 12))).to be false

      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['13'],
        ['MONDAY'],
        ['10', '11'],
        ['MONDAY', 'TUESDAY']
      )
      expect(season.checkin_allowed(Date.new(2016, 9, 15))).to be false
    end

    it 'returns nil if no checks' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        [],
        [],
        ['10', '11'],
        ['MONDAY', 'TUESDAY']
      )
      expect(season.checkin_allowed(Date.new(2016, 9, 13))).to be_nil
    end

    it 'returns nil for date not from season' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['10'],
        ['MONDAY'],
        ['10', '11'],
        ['MONDAY', 'TUESDAY']
      )
      expect(season.checkin_allowed(Date.new(2016, 10, 10))).to be_nil
    end
  end

  describe '#checkout_allowed' do
    it 'returns true if weekdays check passed with empty monthdays' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['10', '11'],
        ['MONDAY', 'TUESDAY'],
        [],
        ['MONDAY'],
      )
      expect(season.checkout_allowed(Date.new(2016, 9, 12))).to be true
    end

    it 'returns true if monthdays check passed with empty weekdays' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['10', '11'],
        ['MONDAY', 'TUESDAY'],
        ['12'],
        [],
      )
      expect(season.checkout_allowed(Date.new(2016, 9, 12))).to be true
    end

    it 'returns true if weekdays check passed and monthdays chech passed' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['10', '11'],
        ['MONDAY', 'TUESDAY'],
        ['12'],
        ['MONDAY'],
      )
      expect(season.checkout_allowed(Date.new(2016, 9, 12))).to be true
    end

    it 'returns false if at least one check fails' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['10', '11'],
        ['MONDAY', 'TUESDAY'],
        ['13'],
        ['MONDAY'],
      )
      expect(season.checkout_allowed(Date.new(2016, 9, 13))).to be false

      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['10', '11'],
        ['MONDAY', 'TUESDAY'],
        ['11'],
        ['MONDAY'],
      )
      expect(season.checkout_allowed(Date.new(2016, 9, 12))).to be false

      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['10', '11'],
        ['MONDAY', 'TUESDAY'],
        ['13'],
        ['MONDAY'],
      )
      expect(season.checkout_allowed(Date.new(2016, 9, 15))).to be false
    end

    it 'returns nil if no checks' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['10', '11'],
        ['MONDAY', 'TUESDAY'],
        [],
        [],
      )
      expect(season.checkout_allowed(Date.new(2016, 9, 13))).to be_nil
    end

    it 'returns nil for date not from season' do
      season = Avantio::Entities::OccupationalRule::Season.new(
        Date.new(2016, 9, 1),
        Date.new(2016, 9, 30),
        5,
        nil,
        ['10', '11'],
        ['MONDAY', 'TUESDAY'],
        ['10'],
        ['MONDAY'],
      )
      expect(season.checkout_allowed(Date.new(2016, 10, 10))).to be_nil
    end
  end
end
