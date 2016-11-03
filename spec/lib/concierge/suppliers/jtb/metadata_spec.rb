require 'spec_helper'

RSpec.describe Workers::Suppliers::JTB::Metadata do
  include Support::Factories

  let(:supplier) { create_supplier(name: JTB::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }

  subject { described_class.new(host) }

  describe '#perform' do
    it 'announces an error if db actualization fails' do
      allow_any_instance_of(JTB::Sync::Actualizer).to receive(:actualize) do
        Result.error(:error, 'Description')
      end

      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq JTB::Client::SUPPLIER_NAME
      expect(error.code).to eq 'error'
      expect(error.description).to eq 'Description'
    end

    described_class::SKIPPABLE_ERROR_CODES.each do |error_code|
      it "skips property if mapper returns skipable error #{error_code}" do
        allow_any_instance_of(JTB::Sync::Actualizer).to receive(:actualize) { Result.new(true) }
        allow(JTB::Repositories::HotelRepository).to receive(:english_ryokans).and_return(
          [double(jtb_hotel_code: '1234'), double(jtb_hotel_code: '2345')]
        )
        allow_any_instance_of(JTB::Mappers::RoomoramaProperty).to receive(:build) { Result.error(error_code) }

        subject.perform

        sync = SyncProcessRepository.last
        expect(sync.successful).to eq true
        expect(sync.skipped_properties_count).to eq 2
        expect(sync.stats[:properties_skipped].length).to eq 1
        expect(sync.stats[:properties_skipped][0]['reason']).to eq error_code.to_s
        expect(sync.stats[:properties_skipped][0]['ids']).to eq ['1234', '2345']
      end
    end

    it 'doesnot sync calendar for not synced properties' do
      allow_any_instance_of(JTB::Sync::Actualizer).to receive(:actualize) { Result.new(true) }
      allow(JTB::Repositories::HotelRepository).to receive(:english_ryokans).and_return(
        [double(jtb_hotel_code: '1234'), double(jtb_hotel_code: '2345')]
      )
      allow_any_instance_of(JTB::Mappers::RoomoramaProperty).to receive(:build) { Result.error(:error) }
      expect(subject).not_to receive(:sync_calendar)
      subject.perform
    end

    context 'success' do
      let(:image) do
        Roomorama::Image.new('identifier').tap do |image|
          image.url = 'http://image.org'
        end
      end
      before do
        allow_any_instance_of(JTB::Sync::Actualizer).to receive(:actualize) { Result.new(true) }
        allow_any_instance_of(JTB::Mappers::RoomoramaProperty).to receive(:build) do
          Result.new(
            Roomorama::Property.new('1234').tap do |property|
              property.add_image(image)
            end
          )
        end
        allow(JTB::Repositories::HotelRepository).to receive(:english_ryokans).and_return(
          [double(jtb_hotel_code: '1234'), double(jtb_hotel_code: '2345')]
        )
      end

      it 'finalizes synchronisations and call calendar sync' do
        expect(subject).to receive(:sync_calendar).and_return(true)
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
        expect(subject.property_synchronisation).to receive(:finish!)
        expect(subject.calendar_synchronisation).to receive(:finish!)
        subject.perform
      end

      it 'doesnt create property with unsuccessful publishing' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error('fail') }
        expect {
          subject.perform
        }.to_not change { PropertyRepository.count }
      end

      it 'creates valid properties in database' do
        expect(subject).to receive(:sync_calendar).and_return(true)
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
        expect {
          subject.perform
        }.to change { PropertyRepository.count }.by(1)
      end
    end
  end
end
