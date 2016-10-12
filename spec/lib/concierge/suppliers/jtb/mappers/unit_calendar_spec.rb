require 'spec_helper'

RSpec.describe JTB::Mappers::UnitCalendar do
  include Support::JTB::Factories

  let(:today) { Date.new(2016, 10, 8) }

  before do
    allow(Date).to receive(:today).and_return(today)
  end

  describe '#build' do
    let(:room) { create_room_type }
    let(:u_id) { JTB::UnitId.from_jtb_codes(room.room_type_code, room.room_code) }

    before do
      create_rate_plan
      create_rate_plan({ rate_plan_id: 'CHUHW0101TRP2PSG'})
      create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG' })
      create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG', service_date: '2016-10-11' })
      create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG', service_date: '2016-10-12', number_of_units: 0 })
      create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG', service_date: '2016-10-13', sale_status: '0' })
      create_room_stock
      create_room_stock({ service_date: '2016-10-11' })
      create_room_stock({ service_date: '2016-10-12', number_of_units: 0 })
      create_room_stock({ service_date: '2016-10-13', sale_status: '0' })
      create_room_price
      create_room_price({ date: '2016-10-11', room_rate: 9010.0 })
      create_room_price({ date: '2016-10-12', room_rate: 8010.0 })
      create_room_price({ date: '2016-10-13', room_rate: 7010.0 })
      create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG' })
      create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG', date: '2016-10-11', room_rate: 9011.0 })
      create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG', date: '2016-10-12', room_rate: 8011.0 })
      create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG', date: '2016-10-13', room_rate: 7011.0 })
    end

    it 'returns error if room is unknown' do
      result = subject.build('unknownunit')

      expect(result).to be_a(Result)
      expect(result.success?).to be false
      expect(result.error.code).to eq(:unknown_room)
    end

    context 'valid calendar' do
      let(:result) { subject.build(u_id.unit_id) }

      it 'returns valid mapped calendar' do
        expect(result).to be_a(Result)
        expect(result.success?).to be true

        calendar = result.value

        expect(calendar).to be_a(Roomorama::Calendar)
        expect { calendar.validate! }.to_not raise_error
        expect(calendar.identifier).to eq('SGL|CHUHW01RM0000001')
      end

      it 'returns not empty calendar' do
        expect(result.value.entries).not_to be_empty
      end

      it 'returns filled entries' do
        entry = result.value.entries.detect { |e| e.date == Date.new(2016, 10, 11) }

        expect(entry.nightly_rate).to eq(9010.0)
        expect(entry.available).to be true
      end
    end


  end
end