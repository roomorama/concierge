require 'spec_helper'

RSpec.describe Workers::Suppliers::JTB::Availabilities do
  include Support::Factories

  let(:supplier) { create_supplier(name: JTB::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }
  let!(:properties) do
    create_property(
      {
        host_id: host.id,
        data: {
          title: "Studio Apartment in Madrid",
          type:  "bnb",
          nightly_rate: 10,
          images: [
            { identifier: "PROP1IMAGE", url: "https://www.example.org/image.png" }
          ],
          units: [
            {
              identifier: 'unit1'
            }
          ]
        }
      }
    )
  end
  let(:unit_calendar) do
    Roomorama::Calendar.new('unit1').tap do |calendar|
      calendar.add(
        Roomorama::Calendar::Entry.new(
          date: Date.today,
          available: true,
          nightly_rate: 100
        )
      )
    end
  end

  subject { described_class.new(host) }

  describe '#perform' do

    context 'success' do
      before do
        allow_any_instance_of(JTB::Sync::Actualizer).to receive(:actualize) { Result.new(true) }
        allow_any_instance_of(JTB::Mappers::UnitCalendar).to receive(:build) do
          Result.new(unit_calendar)
        end
      end

      it 'finalizes synchronisation' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
        expect(subject.synchronisation).to receive(:finish!)
        subject.perform
      end

      it 'doesnt create property with unsuccessful publishing' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error('fail') }
        expect {
          subject.perform
        }.to_not change { PropertyRepository.count }
      end

      it 'creates valid properties in database' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
        expect(subject.synchronisation).to receive(:run_operation)
        subject.perform
      end
    end
  end
end