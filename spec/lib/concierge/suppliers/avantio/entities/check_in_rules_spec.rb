require 'spec_helper'

RSpec.describe Avantio::Entities::CheckInRules do
  include Support::Fixtures

  subject do
    described_class.new.tap do |result|
      rules.each { |r| result.add_rule(r)}
    end
  end

  describe '#to_s' do

    context 'anytime' do
      let(:rules) do
        [
          described_class::Rule.new(
            1, 1, 31, 12, '00:00', '00:00', %w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
          )
        ]
      end

      it 'returns anytime' do
        expect(subject.to_s).to eq(
          "Check-in time:\n"\
          "  anytime"
        )
      end
    end

    context 'season with the same time for all weekdays' do
      let(:rules) do
        [
          described_class::Rule.new(
            1, 1, 31, 12, '10:00', '11:00', %w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
          )
        ]
      end

      it 'returns string without weekdays' do
        expect(subject.to_s).to eq(
          "Check-in time:\n"\
          "  from 10:00 to 11:00"
        )
      end
    end

    context 'different time for different weekdays' do
      let(:rules) do
        [
          described_class::Rule.new(
            1, 1, 31, 12, '10:00', '11:00', %w(Monday Tuesday Wednesday)
          ),
          described_class::Rule.new(
            1, 1, 31, 12, '10:30', '11:30', %w(Thursday Friday Saturday Sunday)
          )
        ]
      end

      it 'returns string without weekdays' do
        expect(subject.to_s).to eq(
          "Check-in time:\n"\
          "  Sunday: from 10:30 to 11:30\n"\
          "  Monday: from 10:00 to 11:00\n"\
          "  Tuesday: from 10:00 to 11:00\n"\
          "  Wednesday: from 10:00 to 11:00\n"\
          "  Thursday: from 10:30 to 11:30\n"\
          "  Friday: from 10:30 to 11:30\n"\
          "  Saturday: from 10:30 to 11:30"
        )
      end
    end

    context 'different time for different weekdays (not all weekdays)' do
      let(:rules) do
        [
          described_class::Rule.new(
            1, 1, 31, 12, '10:00', '11:00', %w(Monday Tuesday Wednesday)
          ),
          described_class::Rule.new(
            1, 1, 31, 12, '10:30', '11:30', %w(Thursday Friday)
          )
        ]
      end

      it 'returns string without weekdays' do
        expect(subject.to_s).to eq(
          "Check-in time:\n"\
          "  Monday: from 10:00 to 11:00\n"\
          "  Tuesday: from 10:00 to 11:00\n"\
          "  Wednesday: from 10:00 to 11:00\n"\
          "  Thursday: from 10:30 to 11:30\n"\
          "  Friday: from 10:30 to 11:30"
        )
      end
    end

    context 'several seasons' do
      let(:rules) do
        [
          described_class::Rule.new(
            1, 1, 1, 6, '10:00', '11:00', %w(Monday Tuesday Wednesday)
          ),
          described_class::Rule.new(
            2, 6, 31, 12, '10:30', '11:30', %w(Thursday Friday)
          )
        ]
      end

      it 'returns string with all seasons' do
        expect(subject.to_s).to eq(
          "Check-in time:\n"\
          "  1 Jan - 1 Jun\n"\
          "    Monday: from 10:00 to 11:00\n"\
          "    Tuesday: from 10:00 to 11:00\n"\
          "    Wednesday: from 10:00 to 11:00\n"\
          "  2 Jun - 31 Dec\n"\
          "    Thursday: from 10:30 to 11:30\n"\
          "    Friday: from 10:30 to 11:30"
        )
      end
    end
  end
end
