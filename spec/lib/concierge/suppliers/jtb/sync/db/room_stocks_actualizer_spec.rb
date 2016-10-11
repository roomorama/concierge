require 'spec_helper'

RSpec.describe JTB::Sync::DB::RoomStocksActualizer do
  let(:room_stock_attributes) do
    {
      city_code: "CHU",
      hotel_code: "W01",
      rate_plan_id: "CHUHW0101TRP1DBL",
      service_date: "20160601",
      number_of_units: "0",
      closing_date: "20160531",
      sale_status: "0",
      reservation_closing_date: "20160531",
   }
  end

  subject { described_class.new(tmp_path)}

  describe '#actualize' do
    context 'when diff file is empty' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_stocks', 'empty_diff') }

      it 'does nothing' do
        create_room_stock(room_stock_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        room_stocks = JTB::Repositories::RoomStockRepository.all
        expect(room_stocks.length).to eq(1)
      end
    end

    context 'when diff file contains create update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_stocks', 'create') }

      it 'creates new room stock' do
        room_stock = JTB::Repositories::RoomStockRepository.by_primary_key('CHU', 'W01', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_stock).to be_nil

        result = subject.actualize
        expect(result.success?).to be true

        room_stocks = JTB::Repositories::RoomStockRepository.all
        expect(room_stocks.length).to eq(1)

        room_stock = JTB::Repositories::RoomStockRepository.by_primary_key('CHU', 'W01', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_stock).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomStock')
        expect(state.file_name).to eq('RoomStock_Diff_20161010013224.zip')
      end
    end

    context 'when diff file contains update update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_stocks', 'update') }

      it 'updates hotel' do
        create_room_stock(room_stock_attributes)
        create_room_stock(room_stock_attributes.merge({hotel_code: 'W02' }))

        result = subject.actualize
        expect(result.success?).to be true

        # Update room_stock
        room_stock = JTB::Repositories::RoomStockRepository.by_primary_key('CHU', 'W01', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_stock.number_of_units).to eq(1)

        # Does not update another room_stock
        room_stock = JTB::Repositories::RoomStockRepository.by_primary_key('CHU', 'W02', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_stock.number_of_units).to eq(0)

        state = JTB::Repositories::StateRepository.by_prefix('RoomStock')
        expect(state.file_name).to eq('RoomStock_Diff_20161010013225.zip')
      end
    end

    context 'when directory contains ALL file' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_stocks', 'with_all') }

      it 'imports the room stocks from the file' do
        result = subject.actualize
        expect(result.success?).to be true

        room_stocks = JTB::Repositories::RoomStockRepository.all
        expect(room_stocks.length).to eq(10)

        state = JTB::Repositories::StateRepository.by_prefix('RoomStock')
        expect(state.file_name).to eq('RoomStock_ALL_20161010.zip')
      end

      it 'clear table before actualisation' do
        create_room_stock(room_stock_attributes.merge({city_code: 'QQQ', hotel_code: 'QQQ' }))

        result = subject.actualize
        expect(result.success?).to be true

        room_stock = JTB::Repositories::RoomStockRepository.by_primary_key('QQQ', 'QQQ', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_stock).to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomStock')
        expect(state.file_name).to eq('RoomStock_ALL_20161010.zip')
      end
    end

    context 'when diff file contains delete update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_stocks', 'delete') }

      it 'delete the hotel' do
        create_room_stock(room_stock_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        room_stocks = JTB::Repositories::RoomStockRepository.all
        expect(room_stocks.length).to eq(0)

        state = JTB::Repositories::StateRepository.by_prefix('RoomStock')
        expect(state.file_name).to eq('RoomStock_Diff_20161010013226.zip')
      end
    end

    context 'when there is some problem during some file actualization' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'room_stocks', 'transaction') }

      it 'imports only files before invalid' do
        result = subject.actualize
        expect(result.success?).to be false

        room_stocks = JTB::Repositories::RoomStockRepository.all
        expect(room_stocks.length).to eq(1)

        room_stock = JTB::Repositories::RoomStockRepository.by_primary_key('CHU', 'W01', 'CHUHW0101TRP1DBL', '20160601')
        expect(room_stock).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomStock')
        expect(state.file_name).to eq('RoomStock_Diff_20161010013227.zip')
      end
    end

    def create_room_stock(attributes)
      JTB::Repositories::RoomStockRepository.create(
        JTB::Entities::RoomStock.new(attributes)
      )
    end
  end
end