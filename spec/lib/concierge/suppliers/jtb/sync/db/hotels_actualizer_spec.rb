require 'spec_helper'

RSpec.describe JTB::Sync::DB::HotelsActualizer do
  let(:hotel_attributes) do
    {
      language: "EN",
      city_code: "CHU",
      hotel_code: "W01",
      jtb_hotel_code: "6440013",
      hotel_name: "Hotel Nikko Himeji",
      location_code: "63",
      hotel_description: "This large city hotel is located in front of JR Himeji Station's south exit and features a large capacity banquet hall.",
      latitude: "N34.49.31.31205",
      longitude: "E134.41.24.7647",
      hotel_type: "H",
      address: "100 Minamiekimae-cho, Himeji-shi, Hyogo Prefecture",
      non_smoking_room: "1",
      parking: "1",
      internet: "1",
      wifi: "0",
      indoor_pool_free: "0",
      indoor_pool_charged: "1",
      outdoor_pool_free: "0",
      outdoor_pool_charged: "0",
      indoor_gym_free: "0",
      indoor_gym_charged: "0",
      outdoor_gym_free: "0",
      outdoor_gym_charged: "0",
      wheelchair_access: "1"
   }
  end

  subject { described_class.new(tmp_path)}

  describe '#actualize' do
    context 'when exception during actualize' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'hotels', 'with_all') }

      it 'returns error with description' do
        allow_any_instance_of(described_class).to receive(:import_file) do
          raise Exception.new
        end

        result = subject.actualize
        expect(result.success?).to be false
        expect(result.error.code).to eq(:jtb_db_actualization_error)
        expect(result.error.data).to eq('Error during import file with prefix `HotelInfo` to DB')
      end
    end

    context 'when diff file is empty' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'hotels', 'empty_diff') }

      it 'does nothing' do
        create_hotel(hotel_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        hotels = JTB::Repositories::HotelRepository.all
        expect(hotels.length).to eq(1)
      end
    end

    context 'when diff file contains create update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'hotels', 'create') }

      it 'creates new hotel' do
        hotel = JTB::Repositories::HotelRepository.by_primary_key('EN', 'CHU', 'W05')
        expect(hotel).to be_nil

        result = subject.actualize
        expect(result.success?).to be true

        hotels = JTB::Repositories::HotelRepository.all
        expect(hotels.length).to eq(1)

        hotel = JTB::Repositories::HotelRepository.by_primary_key('EN', 'CHU', 'W05')
        expect(hotel).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('HotelInfo')
        expect(state.file_name).to eq('HotelInfo_Diff_20161003135625.zip')
      end
    end

    context 'when diff file contains update update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'hotels', 'update') }

      it 'updates hotel' do
        create_hotel(hotel_attributes)
        create_hotel(hotel_attributes.merge({ hotel_code: 'W02', hotel_name: 'Hotel Granvia Okayama' }))

        result = subject.actualize
        expect(result.success?).to be true

        # Update hotel
        hotel = JTB::Repositories::HotelRepository.by_primary_key('EN', 'CHU', 'W01')
        expect(hotel.hotel_name).to eq('Hotel Nikko HimejiXXX')

        # Does not update another hotel
        hotel = JTB::Repositories::HotelRepository.by_primary_key('EN', 'CHU', 'W02')
        expect(hotel.hotel_name).to eq('Hotel Granvia Okayama')

        state = JTB::Repositories::StateRepository.by_prefix('HotelInfo')
        expect(state.file_name).to eq('HotelInfo_Diff_20161003135627.zip')
      end
    end

    context 'when directory contains ALL file' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'hotels', 'with_all') }

      it 'imports the hotels from the file' do
        result = subject.actualize
        expect(result.success?).to be true

        hotels = JTB::Repositories::HotelRepository.all
        expect(hotels.length).to eq(5)

        state = JTB::Repositories::StateRepository.by_prefix('HotelInfo')
        expect(state.file_name).to eq('HotelInfo_ALL_20161003.zip')
      end

      it 'clear table before actualisation' do
        create_hotel(hotel_attributes.merge({ language: 'QQ', city_code: 'QQQ', hotel_code: 'QQQ' }))

        result = subject.actualize
        expect(result.success?).to be true

        hotel = JTB::Repositories::HotelRepository.by_primary_key('QQ', 'QQQ', 'QQQ')
        expect(hotel).to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('HotelInfo')
        expect(state.file_name).to eq('HotelInfo_ALL_20161003.zip')
      end
    end

    context 'when diff file contains delete update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'hotels', 'delete') }

      it 'delete the hotel' do
        create_hotel(hotel_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        hotels = JTB::Repositories::HotelRepository.all
        expect(hotels.length).to eq(0)

        state = JTB::Repositories::StateRepository.by_prefix('HotelInfo')
        expect(state.file_name).to eq('HotelInfo_Diff_20161003135626.zip')
      end
    end

    context 'when there is some problem during some file actualization' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'hotels', 'transaction') }

      it 'imports only files before invalid' do
        result = subject.actualize
        expect(result.success?).to be false

        hotels = JTB::Repositories::HotelRepository.all
        expect(hotels.length).to eq(1)

        hotel = JTB::Repositories::HotelRepository.by_primary_key('EN', 'CHU', 'W05')
        expect(hotel).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('HotelInfo')
        expect(state.file_name).to eq('HotelInfo_Diff_20161003135625.zip')
      end
    end

    context 'when directory contains ALL and Diff files' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'hotels', 'all_and_diff') }

      it 'imports all data' do
        result = subject.actualize
        expect(result.success?).to be true

        hotels = JTB::Repositories::HotelRepository.all
        expect(hotels.length).to eq(5)

        hotel = JTB::Repositories::HotelRepository.by_primary_key('EN', 'CHU', 'W01')
        expect(hotel.hotel_name).to eq('Hotel Nikko HimejiXXX')

        state = JTB::Repositories::StateRepository.by_prefix('HotelInfo')
        expect(state.file_name).to eq('HotelInfo_Diff_20161003135627.zip')
      end
    end

    def create_hotel(attributes)
      JTB::Repositories::HotelRepository.create(
        JTB::Entities::Hotel.new(attributes)
      )
    end
  end
end