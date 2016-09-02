require "spec_helper"

RSpec.describe RentalsUnited::ResponseParser do
  let(:xml_response) do
    "<response>Some Response</response>"
  end

  let(:bad_xml_response) { 'Server Error' }

  it "converts XML response to a safe hash object with given attributes" do
    response_parser = described_class.new
    hash = response_parser.to_hash(xml_response)

    expect(hash).to be_kind_of(Concierge::SafeAccessHash)
    expect(hash.get("response")).to eq("Some Response")
    expect(hash.to_h).to eq({ "response" => "Some Response" })
  end

  it "returns an empty object in case when XML format is not correct" do
    response_parser = described_class.new
    hash = response_parser.to_hash(bad_xml_response)

    expect(hash).to be_kind_of(Concierge::SafeAccessHash)
    expect(hash.to_h).to eq({})
  end
end
