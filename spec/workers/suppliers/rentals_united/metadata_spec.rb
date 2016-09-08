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
        before do
          expect_any_instance_of(RentalsUnited::Importer).to(
            receive(:fetch_locations)
          ).and_return(
           Result.new(
             [RentalsUnited::Entities::Location.new("1505")]
           )
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
          before do
            expect_any_instance_of(RentalsUnited::Importer).to(
              receive(:fetch_location_currencies)
            ).and_return(
              Result.new({"1506" => "EUR", "1606" => "USD"})
            )
          end

          it "fails when there is no currency for location" do
            result = worker.perform
            expect(result).to be_nil

            event = Concierge.context.events.last.to_h
            expect(event[:label]).to eq("Synchronisation Failure")
            expect(event[:message]).to eq(
              "Failed to find currency for location with id `1505`"
            )
            expect(event[:backtrace]).to be_kind_of(Array)
            expect(event[:backtrace].any?).to be true
          end
        end

        describe "when currency for location exists" do
          before do
            expect_any_instance_of(RentalsUnited::Importer).to(
              receive(:fetch_location_currencies)
            ).and_return(
              Result.new({"1505" => "EUR", "1606" => "USD"})
            )
          end

          it "fails when fetching property ids for location returns an error" do
            stub_data = read_fixture("rentals_united/property_ids/error_status.xml")
            stub_call(:post, url) { [200, {}, stub_data] }

            result = worker.perform
            expect(result).to be_nil

            event = Concierge.context.events.last.to_h
            expect(event[:label]).to eq("Synchronisation Failure")
            expect(event[:message]).to eq(
              "Failed to fetch properties for location `1505`"
            )
            expect(event[:backtrace]).to be_kind_of(Array)
            expect(event[:backtrace].any?).to be true
          end

          describe "when #fetch_property_ids is working" do
            before do
              expect_any_instance_of(RentalsUnited::Importer).to(
                receive(:fetch_property_ids)
              ).and_return(
                Result.new(["1234", "2345"])
              )
            end

            it "calls synchronisation block for every property id" do
              expected_property_ids = ["1234", "2345"]

              expected_property_ids.each do |property_id|
                expect(worker.synchronisation).to receive(:start).with(property_id)
              end

              result = worker.perform
              expect(result).to be_kind_of(SyncProcess)
              expect(result.to_h[:successful]).to be true
            end

            it "fails when #fetch_property returns an error" do
              stub_data = read_fixture("rentals_united/properties/error_status.xml")
              stub_call(:post, url) { [200, {}, stub_data] }

              result = worker.perform

              expect(result).to be_kind_of(SyncProcess)

              event = Concierge.context.events.last.to_h
              expect(event[:label]).to eq("Synchronisation Failure")
              expect(event[:message]).to eq(
                "Failed to fetch property with ID `2345`"
              )
              expect(event[:backtrace]).to be_kind_of(Array)
              expect(event[:backtrace].any?).to be true
            end
          end
        end
      end
    end
  end
end
