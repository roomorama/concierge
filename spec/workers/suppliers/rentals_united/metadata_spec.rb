require "spec_helper"

RSpec.describe Workers::Suppliers::RentalsUnited::Metadata do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:host) { create_host }
  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:url) { credentials.url }

  describe "#perform operation" do
    let(:worker) do
      described_class.new(host)
    end

    it "fails when fetching location ids returns an error" do
      stub_data = read_fixture("rentals_united/location_ids/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = worker.perform
      expect(result).to be_nil

      event = Concierge.context.events.last.to_h
      expect(event[:label]).to eq("Synchronisation Failure")
      expect(event[:message]).to eq("Failed to fetch location ids")
      expect(event[:backtrace]).to be_kind_of(Array)
      expect(event[:backtrace].any?).to be true
    end

    describe "when #fetch_location_ids is working" do
      before do
        expect_any_instance_of(RentalsUnited::Importer).to(
          receive(:fetch_location_ids)
        ).and_return(
          Result.new(["1505"])
        )
      end

      it "fails when fetching locations by location_ids returns an error" do
        stub_data = read_fixture("rentals_united/locations/error_status.xml")
        stub_call(:post, url) { [200, {}, stub_data] }

        result = worker.perform
        expect(result).to be_nil

        event = Concierge.context.events.last.to_h
        expect(event[:label]).to eq("Synchronisation Failure")
        expect(event[:message]).to eq("Failed to fetch locations")
        expect(event[:backtrace]).to be_kind_of(Array)
        expect(event[:backtrace].any?).to be true
      end

      describe "when #fetch_locations is working" do
        let(:location) do
          location = RentalsUnited::Entities::Location.new("1505")
          location.country = "France"
          location
        end

        before do
          expect_any_instance_of(RentalsUnited::Importer).to(
            receive(:fetch_locations)
          ).and_return(
           Result.new([location])
          )
        end

        it "fails when fetching location currencies returns an error" do
          stub_data = read_fixture("rentals_united/location_currencies/error_status.xml")
          stub_call(:post, url) { [200, {}, stub_data] }

          result = worker.perform
          expect(result).to be_nil

          event = Concierge.context.events.last.to_h
          expect(event[:label]).to eq("Synchronisation Failure")
          expect(event[:message]).to eq(
            "Failed to fetch locations-currencies mapping"
          )
          expect(event[:backtrace]).to be_kind_of(Array)
          expect(event[:backtrace].any?).to be true
        end

        describe "when #fetch_location_currencies is working" do
          let(:location_currencies) {{"1506" => "EUR", "1606" => "USD"}}
          before do
            expect_any_instance_of(RentalsUnited::Importer).to(
              receive(:fetch_location_currencies)
            ).and_return(
              Result.new(location_currencies)
            )
          end

          it "fails when fetching owners returns an error" do
            stub_data = read_fixture("rentals_united/owners/error_status.xml")
            stub_call(:post, url) { [200, {}, stub_data] }

            result = worker.perform
            expect(result).to be_nil

            event = Concierge.context.events.last.to_h
            expect(event[:label]).to eq("Synchronisation Failure")
            expect(event[:message]).to eq("Failed to fetch owners")
            expect(event[:backtrace]).to be_kind_of(Array)
            expect(event[:backtrace].any?).to be true
          end

          describe "when #fetch_owners is working" do
            let(:owner) do
              double(
                id: '427698',
                first_name: 'John',
                last_name: 'Doe',
                email: 'john.doe@gmail.com',
                phone: '3128329138'
              )
            end

            before do
              expect_any_instance_of(RentalsUnited::Importer).to(
                receive(:fetch_owners)
              ).and_return(
                Result.new([owner])
              )
            end

            it "fails when there is no currency for location and continues worker process" do
              result = worker.perform
              expect(result).to be_kind_of(SyncProcess)

              event = Concierge.context.events.last.to_h
              expect(event[:label]).to eq("Synchronisation Failure")
              expect(event[:message]).to eq(
                "Failed to find currency for location with id `1505`"
              )
              expect(event[:backtrace]).to be_kind_of(Array)
              expect(event[:backtrace].any?).to be true
            end

            describe "when currency for location exists" do
              let(:location_currencies) {{"1505" => "EUR", "1606" => "USD"}}

              it "fails when fetching property ids for location returns an error" do
                stub_data = read_fixture("rentals_united/property_ids/error_status.xml")
                stub_call(:post, url) { [200, {}, stub_data] }

                result = worker.perform
                expect(result).to be_kind_of(SyncProcess)

                event = Concierge.context.events.last.to_h
                expect(event[:label]).to eq("Synchronisation Failure")
                expect(event[:message]).to eq(
                  "Failed to fetch property ids for location `1505`"
                )
                expect(event[:backtrace]).to be_kind_of(Array)
                expect(event[:backtrace].any?).to be true
              end

              describe "when #fetch_property_ids is working" do
                before do
                  expect_any_instance_of(RentalsUnited::Importer).to(
                    receive(:fetch_property_ids)
                  ).and_return(
                    Result.new(["1234"])
                  )
                end

                it "fails when #fetch_properties_by_ids returns an error and continues worker process" do
                  allow_any_instance_of(RentalsUnited::Importer).to receive(:fetch_properties_by_ids) { Result.error('fail') }

                  result = worker.perform
                  expect(result).to be_kind_of(SyncProcess)

                  event = Concierge.context.events.last.to_h
                  expect(event[:label]).to eq("Synchronisation Failure")
                  expect(event[:message]).to eq(
                    "Failed to fetch properties for ids `[\"1234\"]` in location `1505`"
                  )
                  expect(event[:backtrace]).to be_kind_of(Array)
                  expect(event[:backtrace].any?).to be true
                end

                describe "when #fetch_properties_by_ids is working" do
                  before do
                    stub_data = read_fixture("rentals_united/properties/property.xml")
                    stub_call(:post, url) { [200, {}, stub_data] }
                  end

                  describe "when there is no owner for property" do
                    let(:owner) do
                      double(
                        id: '550000',
                        file_name: 'John',
                        last_name: 'Doe',
                        empty: 'john.doe@gmail.com',
                        phone: '3128329138'
                      )
                    end

                    it "fails with owner error and continues worker process" do
                      result = worker.perform
                      expect(result).to be_kind_of(SyncProcess)

                      event = Concierge.context.events.last.to_h
                      expect(event[:label]).to eq("Synchronisation Failure")
                      expect(event[:message]).to eq(
                        "Failed to find owner for property id `519688`"
                      )
                      expect(event[:backtrace]).to be_kind_of(Array)
                      expect(event[:backtrace].any?).to be true
                    end
                  end
                    
                  it "fails when #fetch_seasons returns an error and continues worker process" do
                    result = worker.perform
                    expect(result).to be_kind_of(SyncProcess)

                    event = Concierge.context.events.last.to_h
                    expect(event[:label]).to eq("Synchronisation Failure")
                    expect(event[:message]).to eq(
                      "Failed to fetch seasons for property `519688`"
                    )
                    expect(event[:backtrace]).to be_kind_of(Array)
                    expect(event[:backtrace].any?).to be true
                  end

                  describe "when #fetch_seasons is working" do
                    let(:season) do
                      RentalsUnited::Entities::Season.new(
                        date_from: Date.parse("2016-09-01"),
                        date_to:   Date.parse("2016-09-30"),
                        price:     200.00
                      )
                    end
                    before do
                      expect_any_instance_of(RentalsUnited::Importer).to(
                        receive(:fetch_seasons)
                      ).and_return(
                        Result.new([season])
                      )
                    end

                    it "calls synchronisation block for every property id" do
                      expected_property_ids = ["519688"]

                      expected_property_ids.each do |property_id|
                        expect(worker.property_sync).to receive(:start).with(property_id)
                      end

                      result = worker.perform
                      expect(result).to be_kind_of(SyncProcess)
                      expect(result.to_h[:successful]).to be true
                    end

                    it "creates record in the database" do
                      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

                      expect {
                        worker.perform
                      }.to change { PropertyRepository.count }.by(1)
                    end

                    described_class::IGNORABLE_ERROR_CODES.each do |code|
                      it "skips property from publishing when there was #{code} error" do
                        allow_any_instance_of(RentalsUnited::Mappers::RoomoramaProperty)
                          .to receive(:build_roomorama_property) { Result.error(code) }

                        expect {
                          sync_process = worker.perform
                          expect(sync_process.stats.get("properties_skipped")).to eq(
                            [{ "reason" => code, "ids" => ["519688"] }]
                          )
                        }.to change { PropertyRepository.count }.by(0)
                      end
                    end

                    it 'doesnt create property with unsuccessful publishing' do
                      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error('fail') }

                      expect {
                        worker.perform
                      }.to_not change { PropertyRepository.count }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
