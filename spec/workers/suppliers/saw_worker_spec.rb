require "spec_helper"

RSpec.describe Workers::Suppliers::SAW do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  include Support::SAW::LastContextEvent

  let(:host) { create_host }

  describe "#perform operation" do
    let(:worker) do
      described_class.new(host)
    end

    it "fails when fetching countries returns an error" do
      mock_request(:country, :error)

      result = worker.perform

      expect(result).to be_nil
      expect(last_context_event[:label]).to eq(
        "Synchronisation Failure"
      )
      expect(last_context_event[:message]).to eq(
        "Failed to perform the `#fetch_countries` operation"
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end

    it "fails when fetching properties by countries returns an error" do
      mock_request(:country, :one)
      mock_request(:propertysearch, :error)

      result = worker.perform

      expect(result).to be_nil
      expect(last_context_event[:label]).to eq(
        "Synchronisation Failure"
      )
      expect(last_context_event[:message]).to eq(
        "Failed to perform the `#fetch_properties_by_countries` operation"
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end

    it "calls synchronisation block for every property id" do
      mock_request(:country, :one)
      mock_request(:propertysearch, :success)
      mock_request(:propertyrates, :success)
      mock_request(:propertydetail, :success)

      expected_property_ids = [1787, 1757, 2721, 2893, 1766]

      expected_property_ids.each do |property_id|
        expect(worker.synchronisation).to receive(:start).with(property_id)
      end

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(result.to_h[:successful]).to be true
    end

    describe "handling property detail" do
      before do
        mock_request(:country, :one)
        mock_request(:propertysearch, :success)
        mock_request(:propertyrates, :success)
      end
      it "fails when there is an error while fetching property details" do
        mock_request(:propertydetail, :error)

        result = worker.perform

        expect(result).to be_a(SyncProcess)
        expect(result.successful).to eq false
        expect(last_context_event[:label]).to eq(
          "Synchronisation Failure"
        )
        expect(last_context_event[:message]).to eq(
          "Failed to perform the `#fetch_detailed_property` operation"
        )
        expect(last_context_event[:backtrace]).to be_kind_of(Array)
        expect(last_context_event[:backtrace].any?).to be true
      end

      it "returns built property" do
        mock_request(:propertydetail, :success)

        expect_any_instance_of(Workers::PropertySynchronisation).to receive(:process).exactly(5).times
        result = worker.perform

        expect(result).to be_a(SyncProcess)
        expect(result.successful).to eq true
      end

      it "returns a built property with invalid postal_code" do
        mock_request(:propertydetail, :invalid_postal_code)
        expect_any_instance_of(Workers::PropertySynchronisation).to receive(:skip_property).exactly(5).times
        result = worker.perform

        expect(result).to be_a(SyncProcess)
        expect(result.successful).to eq true
      end
    end
  end
end
