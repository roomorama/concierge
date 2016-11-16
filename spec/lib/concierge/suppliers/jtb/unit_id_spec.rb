require 'spec_helper'

RSpec.describe JTB::UnitId do
  
    let(:room_type_code) { 'TWN' }
    let(:room_code) { 'CHUHW01RM0000001' }
    let(:unit_id) { 'TWN|CHUHW01RM0000001' }
  
    it 'allows to create property id from jtb codes' do
      u_id = described_class.from_jtb_codes(room_type_code, room_code)

      expect(u_id.unit_id).to eq(unit_id)
    end

  it 'allows to create unit id from roomorama property id' do
    u_id = described_class.from_roomorama_unit_id(unit_id)

    expect(u_id.unit_id).to eq(unit_id)
    expect(u_id.room_type_code).to eq(room_type_code)
    expect(u_id.room_code).to eq(room_code)
  end
end 