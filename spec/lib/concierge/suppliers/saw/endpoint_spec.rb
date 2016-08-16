require "spec_helper"

RSpec.describe SAW::Endpoint do
  it "returns an endpoint URL part by its system name" do
    described_class::ENDPOINTS.each do |system_name, url|
      expect(described_class.endpoint_for(system_name)).to eq(url)
    end
  end

  it "raises an exception in case if endpoint could not be found" do
    expect {
      described_class.endpoint_for("unknown-endpoint")
    }.to raise_error(KeyError)
  end
end
