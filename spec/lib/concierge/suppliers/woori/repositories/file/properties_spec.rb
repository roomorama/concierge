require "spec_helper"

RSpec.describe Woori::Repositories::File::Properties do
  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:filename) { "bulk_properties.json" }
  let(:file) { File.join(credentials.import_files_dir, filename ) }
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
