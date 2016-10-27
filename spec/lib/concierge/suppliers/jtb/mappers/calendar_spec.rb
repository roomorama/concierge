require 'spec_helper'

RSpec.describe JTB::Mappers::Calendar do
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

  subject { described_class.new(property) }

  describe '#build' do
    it 'builds calendar' do
      allow_any_instance_of(JTB::Mappers::UnitCalendar).to receive(:build) do
        Result.new(unit_calendar)
      end
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      result = subject.build

      expect(result).to be_a(Result)
      expect(result).to be_success
      expect(result.value).to be_a(Roomorama::Calendar)
      expect(result.value.units.length).to eq(1)
    end

    it 'fails if at unit calendar building fails' do
      allow_any_instance_of(JTB::Mappers::UnitCalendar).to receive(:build).and_return(
        Result.error(:some_error, 'Some error')
      )

      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      result = subject.build

      expect(result).to be_a(Result)
      expect(result).not_to be_success
      expect(result.error.code).to eq(:some_error)
      expect(result.error.data).to eq('Some error')
    end
  end
end