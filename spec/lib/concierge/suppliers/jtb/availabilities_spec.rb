require 'spec_helper'

RSpec.describe Workers::Suppliers::JTB::Availabilities do
  include Support::Factories

  let(:supplier) { create_supplier(name: JTB::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }
  let!(:property) do
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

  subject { described_class.new(host, property) }

  describe '#perform' do

    it 'finalizes synchronisation' do
      allow_any_instance_of(JTB::Mappers::UnitCalendar).to receive(:build) do
        Result.new(unit_calendar)
      end
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      expect(subject.synchronisation).to receive(:finish!)
      subject.perform
    end

    it 'fails if at unit calendar building fails' do
      allow_any_instance_of(JTB::Mappers::UnitCalendar).to receive(:build).and_return(
        Result.error(:some_error, 'Some error')
      )

      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      expect(subject.synchronisation).to receive(:finish!)
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq JTB::Client::SUPPLIER_NAME
      expect(error.code).to eq 'some_error'
      expect(error.description).to eq 'Some error'
    end
  end
end