require 'spec_helper'

RSpec.describe JTB::Sync::DB::RoomPricesActualizer do
  let(:room_price_attributes) do
    {
      city_code: "CHU",
      hotel_code: "W01",
      rate_plan_id: "CHUHW0101TRP1DBL",
      date: "20160601",
      room_rate: "19200.00"
    }
  end

  subject { described_class.new(tmp_path)}

  describe '#actualize' do
    context 'when diff file is empty' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_prices', 'empty_diff') }

      it 'does nothing' do
        create_room_price(room_price_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        room_prices = JTB::Repositories::RoomPriceRepository.all
        expect(room_prices.length).to eq(1)
      end
    end

    context 'when diff file contains create update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_prices', 'create') }

      it 'creates new room_price' do
        room_price = JTB::Repositories::RoomPriceRepository.by_primary_key('CHU', 'W01', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_price).to be_nil

        result = subject.actualize
        expect(result.success?).to be true

        room_prices = JTB::Repositories::RoomPriceRepository.all
        expect(room_prices.length).to eq(1)

        room_price = JTB::Repositories::RoomPriceRepository.by_primary_key('CHU', 'W01', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_price).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomPrice')
        expect(state.file_name).to eq('RoomPrice_Diff_20161010101501.zip')
      end
    end

    context 'when diff file contains update update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_prices', 'update') }

      it 'updates room_price' do
        create_room_price(room_price_attributes)
        create_room_price(room_price_attributes.merge({ hotel_code: 'W02' }))

        result = subject.actualize
        expect(result.success?).to be true

        # Update room_price
        room_price = JTB::Repositories::RoomPriceRepository.by_primary_key('CHU', 'W01', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_price.room_rate).to eq(21200.0)

        # Does not update another room_price
        room_price = JTB::Repositories::RoomPriceRepository.by_primary_key('CHU', 'W02', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_price.room_rate).to eq(19200.0)

        state = JTB::Repositories::StateRepository.by_prefix('RoomPrice')
        expect(state.file_name).to eq('RoomPrice_Diff_20161010101502.zip')
      end
    end

    context 'when directory contains ALL file' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_prices', 'with_all') }

      it 'imports the room_prices from the file' do
        result = subject.actualize
        expect(result.success?).to be true

        room_prices = JTB::Repositories::RoomPriceRepository.all
        expect(room_prices.length).to eq(10)

        state = JTB::Repositories::StateRepository.by_prefix('RoomPrice')
        expect(state.file_name).to eq('RoomPrice_ALL_20161010.zip')
      end

      it 'clear table before actualisation' do
        create_room_price(room_price_attributes.merge({city_code: 'QQQ', hotel_code: 'QQQ' }))

        result = subject.actualize
        expect(result.success?).to be true

        room_price = JTB::Repositories::RoomPriceRepository.by_primary_key('QQQ', 'QQQ', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_price).to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomPrice')
        expect(state.file_name).to eq('RoomPrice_ALL_20161010.zip')
      end
    end

    context 'when diff file contains delete update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_prices', 'delete') }

      it 'deletes the room price' do
        create_room_price(room_price_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        room_prices = JTB::Repositories::RoomPriceRepository.all
        expect(room_prices.length).to eq(0)

        state = JTB::Repositories::StateRepository.by_prefix('RoomPrice')
        expect(state.file_name).to eq('RoomPrice_Diff_20161010101504.zip')
      end
    end

    context 'when there is some problem during some file actualization' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_prices', 'transaction') }

      it 'imports only files before invalid' do
        result = subject.actualize
        expect(result.success?).to be false

        room_prices = JTB::Repositories::RoomPriceRepository.all
        expect(room_prices.length).to eq(1)

        room_price = JTB::Repositories::RoomPriceRepository.by_primary_key('CHU', 'W01', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_price).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomPrice')
        expect(state.file_name).to eq('RoomPrice_Diff_20161010101506.zip')
      end
    end

    context 'when directory contains ALL and Diff files' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_prices', 'all_and_diff') }

      it 'imports all data' do
        result = subject.actualize
        expect(result.success?).to be true

        room_prices = JTB::Repositories::RoomPriceRepository.all
        expect(room_prices.length).to eq(10)

        room_price = JTB::Repositories::RoomPriceRepository.by_primary_key('CHU', 'W01', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_price.room_rate).to eq(21200.0)

        state = JTB::Repositories::StateRepository.by_prefix('RoomPrice')
        expect(state.file_name).to eq('RoomPrice_Diff_20161010101502.zip')
      end
    end

    def create_room_price(attributes)
      JTB::Repositories::RoomPriceRepository.create(
        JTB::Entities::RoomPrice.new(attributes)
      )
    end
  end
end