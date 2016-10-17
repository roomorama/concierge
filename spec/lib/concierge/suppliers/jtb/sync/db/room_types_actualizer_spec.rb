require 'spec_helper'

RSpec.describe JTB::Sync::DB::RoomTypesActualizer do
  let(:room_type_attributes) do
    {
      language: "EN",
      city_code: "CHU",
      hotel_code: "W01",
      room_code: "CHUHW01RM0000001",
      room_grade: "STD",
      room_type_code: "SGL",
      room_name: "Single A",
      min_guests: "1",
      max_guests: "1",
      extra_bed: nil,
      extra_bed_type: nil,
      size1: "15.10",
      size2: nil,
      size3: nil,
      size4: nil,
      size5: nil,
      size6: nil,
      amenities: "100 0000010111011011101000000001000000010010000001000000101110010000001100000010111 11 01000010000  "
   }
  end

  subject { described_class.new(tmp_path)}

  describe '#actualize' do
    context 'when exception during actualize' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_types', 'with_all') }

      it 'returns error with description' do
        allow_any_instance_of(described_class).to receive(:import_file) do
          raise StandartError
        end

        result = subject.actualize
        expect(result.success?).to be false
        expect(result.error.code).to eq(:jtb_db_actualization_error)
        expect(result.error.data).to eq('Error during import file with prefix `RoomType` to DB')
      end
    end

    context 'when diff file is empty' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_types', 'empty_diff') }

      it 'does nothing' do
        create_room_type(room_type_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        room_types = JTB::Repositories::RoomTypeRepository.all
        expect(room_types.length).to eq(1)
      end
    end

    context 'when diff file contains create update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_types', 'create') }

      it 'creates new room type' do
        room_type = JTB::Repositories::RoomTypeRepository.by_primary_key('EN', 'CHU', 'W01', 'CHUHW01RM0000001')
        expect(room_type).to be_nil

        result = subject.actualize
        expect(result.success?).to be true

        room_types = JTB::Repositories::RoomTypeRepository.all
        expect(room_types.length).to eq(1)

        room_type = JTB::Repositories::RoomTypeRepository.by_primary_key('EN', 'CHU', 'W01', 'CHUHW01RM0000001')
        expect(room_type).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomType')
        expect(state.file_name).to eq('RoomType_Diff_20161010013224.zip')
      end
    end

    context 'when diff file contains update update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_types', 'update') }

      it 'updates room type' do
        create_room_type(room_type_attributes)
        create_room_type(room_type_attributes.merge({hotel_code: 'W02' }))

        result = subject.actualize
        expect(result.success?).to be true

        # Update room type
        room_type = JTB::Repositories::RoomTypeRepository.by_primary_key('EN', 'CHU', 'W01', 'CHUHW01RM0000001')
        expect(room_type.amenities).to eq(room_type_attributes[:amenities][0..-2] + '1')

        # Does not update another room type
        room_type = JTB::Repositories::RoomTypeRepository.by_primary_key('EN', 'CHU', 'W02', 'CHUHW01RM0000001')
        expect(room_type.amenities).to eq(room_type_attributes[:amenities])

        state = JTB::Repositories::StateRepository.by_prefix('RoomType')
        expect(state.file_name).to eq('RoomType_Diff_20161010013225.zip')
      end
    end

    context 'when directory contains ALL file' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_types', 'with_all') }

      it 'imports the room types from the file' do
        result = subject.actualize
        expect(result.success?).to be true

        room_types = JTB::Repositories::RoomTypeRepository.all
        expect(room_types.length).to eq(13)

        room_type = room_types.find { |r| r.room_code == 'CHUHW01RM0000001' }
        expect(room_type.amenities).to eq(room_type_attributes[:amenities])

        state = JTB::Repositories::StateRepository.by_prefix('RoomType')
        expect(state.file_name).to eq('RoomType_ALL_20161010.zip')
      end

      it 'clear table before actualisation' do
        create_room_type(room_type_attributes.merge({language: 'QQ', city_code: 'QQQ', hotel_code: 'QQQ' }))

        result = subject.actualize
        expect(result.success?).to be true

        room_type = JTB::Repositories::RoomTypeRepository.by_primary_key('QQ', 'QQQ', 'QQQ', 'CHUHW01RM0000001')
        expect(room_type).to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomType')
        expect(state.file_name).to eq('RoomType_ALL_20161010.zip')
      end
    end

    context 'when diff file contains delete update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_types', 'delete') }

      it 'delete the room type' do
        create_room_type(room_type_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        room_types = JTB::Repositories::RoomTypeRepository.all
        expect(room_types.length).to eq(0)

        state = JTB::Repositories::StateRepository.by_prefix('RoomType')
        expect(state.file_name).to eq('RoomType_Diff_20161010013226.zip')
      end
    end

    context 'when there is some problem during some file actualization' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_types', 'transaction') }

      it 'imports only files before invalid' do
        result = subject.actualize
        expect(result.success?).to be false

        room_types = JTB::Repositories::RoomTypeRepository.all
        expect(room_types.length).to eq(1)

        room_type = JTB::Repositories::RoomTypeRepository.by_primary_key('EN', 'CHU', 'W01', 'CHUHW01RM0000001')
        expect(room_type).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomType')
        expect(state.file_name).to eq('RoomType_Diff_20161010013227.zip')
      end
    end

    context 'when directory contains ALL and Diff files' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_types', 'all_and_diff') }

      it 'imports all data' do
        result = subject.actualize
        expect(result.success?).to be true

        room_types = JTB::Repositories::RoomTypeRepository.all
        expect(room_types.length).to eq(13)

        room_type = JTB::Repositories::RoomTypeRepository.by_primary_key('EN', 'CHU', 'W01', 'CHUHW01RM0000001')
        expect(room_type.amenities).to eq(room_type_attributes[:amenities][0..-2] + '1')

        state = JTB::Repositories::StateRepository.by_prefix('RoomType')
        expect(state.file_name).to eq('RoomType_Diff_20161010013225.zip')
      end
    end

    def create_room_type(attributes)
      JTB::Repositories::RoomTypeRepository.create(
        JTB::Entities::RoomType.new(attributes)
      )
    end
  end
end