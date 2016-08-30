require "spec_helper"

RSpec.describe Woori::Commands::PropertiesFetcher do
  let(:import_files_path) { "spec/fixtures/woori/import_files" }
  let(:location) { Hanami.root.join(import_files_path, filename) }
  let(:file) { File.new(location, 'r') }
  let(:subject) { described_class.new(file) }

  context "when file is empty" do
    let(:filename) { "empty_bulk_properties.json" }

    it "returns result wrapping a unit rates object" do
      properties = subject.load_all_properties
      expect(properties).to eq([])
    end
  end

  context "when file is not empty" do
    let(:filename) { "bulk_properties.json" }

    it "returns result wrapping a unit rates object" do
      properties = subject.load_all_properties
      expect(properties.size).to eq(2)
      expect(properties).to all(be_kind_of(Roomorama::Property))
    end
  end

  context "when file contains not active properties" do
    let(:filename) { "bulk_properties_with_not_active.json" }

    it "returns only active properties" do
      properties = subject.load_all_properties
      expect(properties.size).to eq(1)

      property = properties.first
      expect(property.identifier).to eq("w_w0604019")
    end
  end
end
