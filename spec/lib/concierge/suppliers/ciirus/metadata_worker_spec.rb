require 'spec_helper'

RSpec.describe Workers::Suppliers::Ciirus::Metadata do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: Ciirus::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }
  let(:properties_list) do
    [
      Ciirus::Entities::Property.new(
        {
          property_id: '33680',
          property_name: "Mandy's Magic Villa",
          address: '1234 Dahlia Reserve Drive',
          zip: '34744',
          city: 'Kissimmee',
          bedrooms: 6,
          sleeps: 6,
          min_nights_stay: 0,
          type: 'Villa',
          country: 'UK',
          xco: '28.2238577',
          yco: '-81.4975719',
          bathrooms: 4,
          king_beds: 1,
          queen_beds: 2,
          full_beds: 3,
          twin_beds: 4,
          extra_bed: true,
          sofa_bed: true,
          pets_allowed: true,
          currency_code: 'USD',
          amenities: ['airconditioning', 'gym', 'internet']
        }
      ),
      Ciirus::Entities::Property.new(
        {
          property_id: '33680',
          property_name: "Mandy's Magic Villa",
          address: '1234 Dahlia Reserve Drive',
          zip: '34744',
          city: 'Kissimmee',
          bedrooms: 6,
          sleeps: 6,
          min_nights_stay: 0,
          type: 'Hotel',
          country: 'UK',
          xco: '28.2238577',
          yco: '-81.4975719',
          bathrooms: 4,
          king_beds: 1,
          queen_beds: 2,
          full_beds: 3,
          twin_beds: 4,
          extra_bed: true,
          sofa_bed: true,
          pets_allowed: true,
          currency_code: 'USD',
          amenities: ['airconditioning', 'gym', 'internet']
        }
      )
    ]
  end
  let(:security_deposit) do
    Ciirus::Entities::Extra.new(
      {
        property_id: '33692',
        item_code: 'SD',
        item_description: 'Security Deposit',
        flat_fee: true,
        flat_fee_amount: 2500.00,
        daily_fee: false,
        daily_fee_amount: 0,
        percentage_fee: false,
        percentage: 0,
        mandatory: true,
        minimum_charge: 0.00,
      }
    )
  end
  let(:images) { ['http://image.com/152523'] }
  let(:description) { 'Some description here' }
  let(:success_result) { Result.new(properties_list) }
  let(:rates) do
    [
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2014, 6, 27),
        DateTime.new(2014, 8, 22),
        3,
        157.50
      ),
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2014, 8, 23),
        DateTime.new(2014, 10, 16),
        2,
        141.43
      )
    ]
  end
  let(:permissions) do
    Ciirus::Entities::PropertyPermissions.new(
      {
        property_id: '33680',
        mc_enable_property: true,
        agent_enable_property: true,
        agent_user_id: '33457',
        mc_user_id: '5489',
        native_property: false,
        calendar_sync_property: false,
        aoa_property: false,
        time_share: false,
        online_booking_allowed: true
      })
  end
  let(:today) { Date.new(2014, 7, 14) }

  before do
    allow(Date).to receive(:today).and_return(today)
  end


  subject { described_class.new(host) }

  it 'announces an error if fetching properties fails' do
    allow_any_instance_of(Ciirus::Importer).to receive(:fetch_properties) { Result.error(:soap_error) }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.supplier).to eq Ciirus::Client::SUPPLIER_NAME
    expect(error.code).to eq 'soap_error'
  end

  context 'fetching permissions' do
    before do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_permissions) { Result.error(:soap_error) }
    end

    it 'announces an error if fetching permissions fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Ciirus::Client::SUPPLIER_NAME
      expect(error.code).to eq 'soap_error'
    end

    it 'does not announce an error if permissions are invalid' do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_permissions) { Result.new(permissions) }
      allow_any_instance_of(Ciirus::Validators::PermissionsValidator).to receive(:valid?) { false }
      subject.perform

      error = ExternalErrorRepository.last

      expect(error).to be_nil
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching images' do
    before do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_permissions) { Result.new(permissions) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_images) { Result.error(:soap_error) }
    end

    it 'announces an error if fetching images fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Ciirus::Client::SUPPLIER_NAME
      expect(error.code).to eq 'soap_error'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching description' do
    before do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_permissions) { Result.new(permissions) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_images) { Result.new(images) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_description) { Result.error(:soap_error) }
    end

    it 'announces an error if fetching description fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Ciirus::Client::SUPPLIER_NAME
      expect(error.code).to eq 'soap_error'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching rates' do
    before do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_permissions) { Result.new(permissions) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_images) { Result.new(images) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_description) { Result.new(description) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_rates) { Result.error(:soap_error) }
    end

    it 'announces an error if fetching rates fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Ciirus::Client::SUPPLIER_NAME
      expect(error.code).to eq 'soap_error'
    end

    it 'announces an error if list of actual rates is empty' do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Ciirus::Validators::RateValidator).to receive(:valid?) { false }
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Ciirus::Client::SUPPLIER_NAME
      expect(error.code).to eq 'empty_rates_error'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching security deposit' do
    before do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_permissions) { Result.new(permissions) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_images) { Result.new(images) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_description) { Result.new(description) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_security_deposit) { Result.error(:soap_error) }
    end

    context 'even without security deposit' do
      it 'finalizes synchronisation' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

        expect(subject.synchronisation).to receive(:finish!)
        subject.perform
      end

      it 'creates valid properties in database' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
        expect {
          subject.perform
        }.to change { PropertyRepository.count }.by(1)
      end
    end
  end

  context 'success' do

    before do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_permissions) { Result.new(permissions) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_images) { Result.new(images) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_description) { Result.new(description) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_security_deposit) { Result.new(security_deposit) }
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

    it 'does not create invalid properties in database' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      allow_any_instance_of(Ciirus::Validators::PropertyValidator).to receive(:valid?) { false }
      expect {
        subject.perform
      }.to_not change { PropertyRepository.count }
    end

    it 'does not create properties with invalid permissions in database' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      allow_any_instance_of(Ciirus::Validators::PermissionsValidator).to receive(:valid?) { false }
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