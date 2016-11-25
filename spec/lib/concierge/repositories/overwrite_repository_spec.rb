require "spec_helper"

RSpec.describe OverwriteRepository do
  include Support::Factories

  describe "querying all related overwrites for a property" do
    let(:host) { create_host }
    let(:other_host) { create_host }

    before do
      create_overwrite(supplier_id: host.supplier_id,
                       host_id: host.id,
                       property_identifier: nil)
      create_overwrite(supplier_id: host.supplier_id,
                       host_id: host.id,
                       property_identifier: "ABC")
      # should not be retrieved
      create_overwrite(supplier_id: host.supplier_id,
                       host_id: other_host.id,
                       property_identifier: "ABC")
    end

    let(:relevant_overwrites) { described_class.all_for(identifier:"ABC", host_id: host.id) }
    it { expect(relevant_overwrites.count).to eq 2 }
    it { expect(relevant_overwrites).to be_a Array }
  end
end
