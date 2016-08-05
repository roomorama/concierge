RSpec.shared_examples "paginating records" do

  before do
    2.times { factory.call }
  end

  it "uses the defaults in case the parameters given are nil" do
    collection = described_class.paginate.to_a
    expect(collection.size).to eq 2
  end

  it "uses the defaults in case the parameters given are invalid" do
    collection = described_class.paginate(page: -1, per: -10).to_a
    expect(collection.size).to eq 2
  end

  it "uses the parameters given" do
    collection = described_class.paginate(per: 1).to_a
    expect(collection.size).to eq 1

    collection = described_class.paginate(page: 2).to_a
    expect(collection.size).to eq 0
  end
end
