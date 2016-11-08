require 'spec_helper'

RSpec.describe Workers::Suppliers::Avantio::Metadata do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: Avantio::Client::SUPPLIER_NAME) }
  let!(:host1) { create_host(supplier_id: supplier.id, identifier: 'itsalojamientos') }
  let!(:host2) { create_host(supplier_id: supplier.id, identifier: '138') }
  let!(:host3) { create_host(supplier_id: supplier.id, identifier: '139') }
  let(:attrs) do
    {
      accommodation_code: "60505",
      user_code: "1238513302",
      login_ga: "itsalojamientos",
      name: "Edificio ITS 2/4",
      occupational_rule_id: "204",
      master_kind_code: "1",
      country_iso_code: "ES",
      city: "Alicante",
      lat: "38.5370431",
      lng: "-0.1290771",
      district: "Sin especificar",
      postal_code: "03502",
      street: "",
      number: "",
      block: "",
      door: nil,
      floor: nil,
      currency: "EUR",
      people_capacity: 4,
      minimum_occupation: 1,
      bedrooms: 1,
      double_beds: nil,
      individual_beds: 2,
      individual_sofa_beds: 2,
      double_sofa_beds: nil,
      housing_area: nil,
      area_unit: "m",
      bathtub_bathrooms: 1,
      shower_bathrooms: nil,
      pool_type: "comunitaria",
      tv: true,
      fire_place: false,
      garden: false,
      bbq: false,
      terrace: false,
      fenced_plot: false,
      elevator: false,
      dvd: false,
      balcony: false,
      gym: false,
      handicapped_facilities: "",
      number_of_kitchens: 1,
      washing_machine: true,
      pets_allowed: true,
      security_deposit_amount: nil,
      security_deposit_type: nil,
      security_deposit_currency_code: nil,
      services_cleaning: nil,
      services_cleaning_rate: nil,
      services_cleaning_required: nil,
      bed_linen: nil,
      towels: nil,
      parking: nil,
      airconditioning: true,
      free_cleaning: nil,
      internet: nil
    }
  end
  let(:properties) do
    {
      'itsalojamientos' => [Avantio::Entities::Accommodation.new(attrs)],
      '138' => [Avantio::Entities::Accommodation.new(
        attrs.merge({user_code: '123123', login_ga: '138'})
      )]
    }
  end
  let(:descriptions) do
    {
      '60505|1238513302|itsalojamientos' => Avantio::Entities::Description.new(
        '60505',
        '1238513302',
        'itsalojamientos',
        ['http://image.org/1'],
        'some description'
      )
    }
  end
  let(:occupational_rules) do
    {
      '204' => Avantio::Entities::OccupationalRule.new(
        '204',
        [
          Avantio::Entities::OccupationalRule::Season.new(
            Date.new(2016, 6, 10),
            Date.new(2017, 6, 10),
            2,
            (1..31).map(&:to_s),
            ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'],
            (1..31).map(&:to_s),
            ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY']
          )
        ]
      )
    }
  end
  let(:rates) do
    {
      '60505|1238513302|itsalojamientos' => Avantio::Entities::Rate.new(
        '60505',
        '1238513302',
        'itsalojamientos',
        [
          Avantio::Entities::Rate::Period.new(
            Date.new(2016, 6, 10),
            Date.new(2017, 6, 10),
            250.0
          )
        ]
      )
    }
  end
  let(:availabilities) do
    {
      '60505|1238513302|itsalojamientos' => Avantio::Entities::Availability.new(
        '60505',
        '1238513302',
        'itsalojamientos',
        '204',
        [
          Avantio::Entities::Availability::Period.new(
            DateTime.new(2014, 8, 24),
            DateTime.new(2014, 8, 27),
            'AVAILABLE'
          ),
          Avantio::Entities::Availability::Period.new(
            DateTime.new(2014, 8, 27),
            DateTime.new(2014, 8, 31),
            'UNAVAILABLE'
          ),
          Avantio::Entities::Availability::Period.new(
            DateTime.new(2014, 9, 11),
            DateTime.new(2020, 10, 16),
            'AVAILABLE'
          ),
        ]
      )
    }
  end

  let(:today) { Date.new(2016, 7, 14) }

  before do
    allow(Date).to receive(:today).and_return(today)
  end

  subject { described_class.new(supplier) }

  context 'there are events from previous syncs in current context' do
    before do
      Concierge.context = Concierge::Context.new(type: 'batch')

      sync_process = Concierge::Context::SyncProcess.new(
        worker:     'metadata',
        host_id:    'UNRELATED_HOST',
        identifier: 'UNRELATED_PROPERTY'
      )
      Concierge.context.augment(sync_process)
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_properties) { Result.error(:error) }
    end

    it 'announces an error without any unrelated context' do
      subject.perform
      error = ExternalErrorRepository.last
      expect(error.context.get('events').to_s).to_not include('UNRELATED_PROPERTY')
    end
  end

  it 'announces an error if fetching properties fails' do
    allow_any_instance_of(Avantio::Importer).to receive(:fetch_properties) { Result.error(:error) }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
    expect(error.code).to eq 'error'
  end

  context 'fetching descriptions' do
    before do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_properties) { Result.new(properties) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_descriptions) { Result.error(:error) }
    end

    it 'announces an error if fetching descriptions fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'error'
    end

    it 'skip property if descriptions not found for property' do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_descriptions) { Result.new({}) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.new(occupational_rules) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }

      expect(subject).to receive(:skip_property).exactly(2).times.and_call_original

      subject.perform
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching occupational rules' do
    before do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_properties) { Result.new(properties) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_descriptions) { Result.new(descriptions) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.error(:error) }
    end

    it 'announces an error if fetching rules fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'error'
    end

    it 'skip property if occupational rules not found for property' do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.new({}) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }

      expect(subject).to receive(:skip_property).exactly(2).times.and_call_original
      subject.perform
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching rates' do
    before do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_properties) { Result.new(properties) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_descriptions) { Result.new(descriptions) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.new(occupational_rules) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.error(:error) }
    end

    it 'announces an error if fetching rates fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'error'
    end

    it 'skip property if rates not found for property' do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.new({}) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }

      expect(subject).to receive(:skip_property).exactly(2).times.and_call_original

      subject.perform
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching availabilities' do
    before do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_properties) { Result.new(properties) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_descriptions) { Result.new(descriptions) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.new(occupational_rules) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.error(:error) }
    end

    it 'announces an error if fetching availabilities fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'error'
    end

    it 'skip property if availabilities not found for property' do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.new({}) }

      expect(subject).to receive(:skip_property).exactly(2).times.and_call_original
      subject.perform
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'success' do

    before do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_properties) { Result.new(properties) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_descriptions) { Result.new(descriptions) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.new(occupational_rules) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }
    end

    it 'finalizes synchronisation for each host' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect(subject).to receive(:finish_sync).exactly(3).times
      subject.perform
    end

    it 'calls perform_for_host for each host' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect(subject).to receive(:perform_for_host).with(host1, any_args).exactly(1).times.and_call_original
      expect(subject).to receive(:perform_for_host).with(host2, any_args).exactly(1).times.and_call_original
      expect(subject).to receive(:perform_for_host).with(host3, any_args).exactly(1).times.and_call_original
      subject.perform
    end

    it 'doesnt create property with unsuccessful publishing' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error('fail') }
      expect {
        subject.perform
      }.to_not change { PropertyRepository.count }
    end

    it 'does not create invalid properties in database' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      allow_any_instance_of(Avantio::Validators::PropertyValidator).to receive(:valid?) { false }
      expect {
        subject.perform
      }.to_not change { PropertyRepository.count }
    end

    it 'does not create properties with invalid descriptions in database' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      allow_any_instance_of(Avantio::Validators::DescriptionValidator).to receive(:valid?) { false }
      expect {
        subject.perform
      }.to_not change { PropertyRepository.count }
    end

    it 'creates valid properties in database' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      expect {
        subject.perform
      }.to change { PropertyRepository.count }.by(1)
    end
  end
end
