require "spec_helper"

RSpec.describe Workers::Suppliers::RentalsUnited::Metadata do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:host) { create_host }
  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }
  let(:url) { credentials.url }

  describe "#perform operation" do
    let(:worker) do
      described_class.new(host)
    end

    it "fails when fetching owner returns an error" do
      failing_owner_fetch!

      result = worker.perform
      expect(result).to be_nil
      expect(worker.property_sync.sync_record.successful).to be false

      expect_sync_error("Failed to fetch owner with owner_id `host`")
    end

    it "fails when fetching properties collection for owner returns an error" do
      successful_owner_fetch!
      failing_properties_collection_fetch!

      result = worker.perform
      expect(result).to be_nil
      expect(worker.property_sync.sync_record.successful).to be false

      expect_sync_error("Failed to fetch property ids collection for owner `host`")
    end

    it "fails when fetching locations by location_ids returns an error" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      failing_locations_fetch!

      result = worker.perform
      expect(result).to be_nil
      expect(worker.property_sync.sync_record.successful).to be false

      expect_sync_error("Failed to fetch locations with ids `[\"1505\"]`")
    end

    it "fails when fetching location currencies returns an error" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      failing_location_currencies_fetch!

      result = worker.perform
      expect(result).to be_nil
      expect(worker.property_sync.sync_record.successful).to be false

      expect_sync_error("Failed to fetch locations-currencies mapping")
    end

    it "finishes sync when there is no properties to iterate on" do
      successful_owner_fetch!
      successful_but_empty_properties_collection_fetch!
      successful_locations_fetch!
      successful_location_currencies_fetch!

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(worker.property_sync.sync_record.successful).to be true
    end

    it "fails when there is no location for property and continues worker process" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_but_wrong_locations_fetch!
      successful_location_currencies_fetch!

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(worker.property_sync.sync_record.successful).to be true

      expect_sync_error("Failed to find location with id `1505`")
    end

    it "fails when there is no currency for location and continues worker process" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      successful_but_wrong_location_currencies_fetch!

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(worker.property_sync.sync_record.successful).to be true

      expect_sync_error("Failed to find currency for location with id `1505`")
    end

    it "fails when #fetch_property returns an error" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      successful_location_currencies_fetch!
      failing_property_fetch!

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(worker.property_sync.sync_record.successful).to be false

      expect_sync_error("Failed to fetch property with property_id `519688`")
    end

    it "fails when #fetch_seasons returns an error" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      successful_location_currencies_fetch!
      successful_property_fetch!
      failing_seasons_fetch!

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(worker.property_sync.sync_record.successful).to be false

      expect_sync_error("Failed to fetch seasons for property `519688`")
    end

    described_class::IGNORABLE_ERROR_CODES.each do |code|
      it "skips property from publishing when there was #{code} error" do
        successful_owner_fetch!
        successful_properties_collection_fetch!
        successful_locations_fetch!
        successful_location_currencies_fetch!
        successful_property_fetch!
        successful_seasons_fetch!
        failing_property_build!(code)

        expected_property_ids = ["519688"]
        expected_property_ids.each do |property_id|
          expect {
            sync_process = worker.perform

            expect(sync_process.stats.get("properties_skipped")).to eq(
              [{ "reason" => code, "ids" => [property_id] }]
            )
            expect(worker.property_sync).not_to(
              receive(:start).with(property_id)
            )
          }.to change { PropertyRepository.count }.by(0)
        end
        expect(worker.property_sync.sync_record.successful).to be true
      end
    end

    it "calls synchronisation block for every property id" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      successful_location_currencies_fetch!
      successful_property_fetch!
      successful_seasons_fetch!

      expected_property_ids = ["519688"]
      expected_property_ids.each do |property_id|
        expect(worker.property_sync).to receive(:start).with(property_id)
      end

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(result.to_h[:successful]).to be true
      expect(worker.property_sync.sync_record.successful).to be true
    end

    it "creates record in the database" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      successful_location_currencies_fetch!
      successful_property_fetch!
      successful_seasons_fetch!
      successful_publishing_to_roomorama!

      expect {
        worker.perform
      }.to change { PropertyRepository.count }.by(1)
      expect(worker.property_sync.sync_record.successful).to be true
    end

    it "doesnt create property with unsuccessful publishing" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      successful_location_currencies_fetch!
      successful_property_fetch!
      successful_seasons_fetch!
      failing_publishing_to_roomorama!

      expect {
        worker.perform
      }.to_not change { PropertyRepository.count }
      expect(worker.property_sync.sync_record.successful).to be true
    end

    it "starts calendar sync when property" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      successful_location_currencies_fetch!
      successful_property_fetch!
      successful_seasons_fetch!
      successful_publishing_to_roomorama!
      already_synced_property!

      expected_property_ids = ["519688"]
      expected_property_ids.each do |property_id|
        expect(worker.calendar_sync).to receive(:start).with(property_id)
      end

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(result.to_h[:successful]).to be true
      expect(worker.calendar_sync.sync_record.successful).to be true
    end

    it "fails when #fetch_availabilities returns an error" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      successful_location_currencies_fetch!
      successful_property_fetch!
      successful_seasons_fetch!
      successful_publishing_to_roomorama!
      already_synced_property!
      failing_availabilities_fetch!

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)

      expect_sync_error("Failed to fetch availabilities for property `519688`")
    end

    it "finishes everything" do
      successful_owner_fetch!
      successful_properties_collection_fetch!
      successful_locations_fetch!
      successful_location_currencies_fetch!
      successful_property_fetch!
      successful_seasons_fetch!
      successful_publishing_to_roomorama!
      already_synced_property!
      successful_availabilities_fetch!

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(result.to_h[:successful]).to be true
    end

    private
    def expect_sync_error(message)
      context_event = Concierge.context.events.last.to_h

      expect(context_event[:label]).to eq("Synchronisation Failure")
      expect(context_event[:message]).to eq(message)
      expect(context_event[:backtrace]).to be_kind_of(Array)
      expect(context_event[:backtrace].any?).to be true
    end

    def failing_owner_fetch!
      stub_importer_action!(:fetch_owner, Result.error('fail'))
    end

    def failing_properties_collection_fetch!
      stub_importer_action!(
        :fetch_properties_collection_for_owner,
        Result.error('fail')
      )
    end

    def failing_locations_fetch!
      stub_importer_action!(:fetch_locations, Result.error('fail'))
    end

    def failing_location_currencies_fetch!
      stub_importer_action!(:fetch_location_currencies, Result.error('fail'))
    end

    def failing_property_fetch!
      stub_importer_action!(:fetch_property, Result.error('fail'))
    end

    def failing_seasons_fetch!
      stub_importer_action!(:fetch_seasons, Result.error('fail'))
    end

    def failing_availabilities_fetch!
      stub_importer_action!(:fetch_availabilities, Result.error('fail'))
    end

    def failing_publishing_to_roomorama!
      stub_publishing_to_roomorama!(Result.error('fail'))
    end

    def failing_property_build!(code)
      allow_any_instance_of(RentalsUnited::Mappers::RoomoramaProperty)
        .to receive(:build_roomorama_property) { Result.error(code) }
    end

    def successful_owner_fetch!
      owner = double(
        id: 'host',
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@gmail.com',
        phone: '3128329138'
      )

      stub_importer_action!(:fetch_owner, Result.new(owner))
    end

    def successful_properties_collection_fetch!
      collection = RentalsUnited::Entities::PropertiesCollection.new(
        [
          { property_id: '519688', location_id: '1505' }
        ]
      )

      stub_importer_action!(
        :fetch_properties_collection_for_owner,
        Result.new(collection)
      )
    end

    def successful_but_empty_properties_collection_fetch!
      collection = RentalsUnited::Entities::PropertiesCollection.new([])

      stub_importer_action!(
        :fetch_properties_collection_for_owner,
        Result.new(collection)
      )
    end

    def successful_locations_fetch!
      location = RentalsUnited::Entities::Location.new("1505")
      location.country = "France"

      stub_importer_action!(:fetch_locations, Result.new([location]))
    end

    def successful_but_wrong_locations_fetch!
      location = RentalsUnited::Entities::Location.new("1506")
      location.country = "France"

      stub_importer_action!(:fetch_locations, Result.new([location]))
    end

    def successful_location_currencies_fetch!
      location_currencies = {"1505" => "EUR", "1606" => "USD"}

      stub_importer_action!(
        :fetch_location_currencies,
        Result.new(location_currencies)
      )
    end

    def successful_but_wrong_location_currencies_fetch!
      location_currencies = {"2505" => "EUR", "2606" => "USD"}

      stub_importer_action!(
        :fetch_location_currencies,
        Result.new(location_currencies)
      )
    end

    def successful_property_fetch!
      stub_data = read_fixture("rentals_united/properties/property.xml")
      stub_call(:post, url) { [200, {}, stub_data] }
    end

    def successful_seasons_fetch!
      season = RentalsUnited::Entities::Season.new(
        date_from: Date.parse("2016-09-01"),
        date_to:   Date.parse("2016-09-30"),
        price:     200.00
      )
      stub_importer_action!(:fetch_seasons, Result.new([season]))
    end

    def successful_availabilities_fetch!
      availability = RentalsUnited::Entities::Availability.new(
        date:         Date.parse("2016-09-01"),
        available:    true,
        minimum_stay: 1,
        changeover:   "4"
      )
      stub_importer_action!(:fetch_availabilities, Result.new([availability]))
    end

    def successful_publishing_to_roomorama!
      stub_publishing_to_roomorama!(Result.new('success'))
    end

    def already_synced_property!
      allow_any_instance_of(Hanami::Model::Adapters::Sql::Query)
        .to receive(:count) { 1 }
    end

    def stub_publishing_to_roomorama!(result)
      allow_any_instance_of(Roomorama::Client).to receive(:perform) do
        result
      end
    end

    def stub_importer_action!(action, result)
      expect_any_instance_of(RentalsUnited::Importer)
        .to(receive(action))
        .and_return(result)
    end
  end
end
