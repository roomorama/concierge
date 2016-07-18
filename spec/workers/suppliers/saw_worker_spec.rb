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

      expected_property_ids = [1787, 1757, 2721, 2893, 1766]

      expected_property_ids.each do |intenal_id|
        expect(worker.synchronisation).to receive(:start).with(intenal_id)
      end

      result = worker.perform
      expect(result).to be_kind_of(SyncProcess)
      expect(result.to_h[:successful]).to be true
    end
    
    it "fails when there is an error while fetching property details" do
      mock_request(:propertydetail, :error)

      property = SAW::Entities::BasicProperty.new
      result = worker.fetch_details_and_build_property(property)

      expect(result).to be_kind_of(Result)
      expect(result).not_to be_success
      expect(result.error.code).to eq("0000")
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

      property = SAW::Entities::BasicProperty.new
      result = worker.fetch_details_and_build_property(property)

      expect(result).to be_kind_of(Result)
      expect(result).to be_success
      expect(result.value).to be_kind_of(Roomorama::Property)
    end
  end
end
