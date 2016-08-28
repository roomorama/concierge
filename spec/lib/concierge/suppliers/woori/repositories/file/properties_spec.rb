require "spec_helper"

RSpec.describe Woori::Repositories::File::Properties do
  let(:import_files_path) { "spec/fixtures/woori/import_files" }
  let(:location) { Hanami.root.join(import_files_path, filename) }
  let(:file) { File.new(location, 'r') }
  let(:subject) { described_class.new(file) }

  context "when file is empty" do
    let(:filename) { "empty_bulk_properties.json" }

    it "returns result wrapping a unit rates object" do
      properties = subject.all
      expect(properties).to eq([])
    end
  end

  context "when file is not empty" do
    let(:filename) { "bulk_properties.json" }

    it "returns result wrapping a unit rates object" do
      properties = subject.all
      expect(properties.size).to eq(2)
      expect(properties).to all(be_kind_of(Roomorama::Property))
    end
  end
end
