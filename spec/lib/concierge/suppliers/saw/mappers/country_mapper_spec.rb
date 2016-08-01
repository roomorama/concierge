require 'spec_helper'

module SAW
  RSpec.describe Mappers::Country do
    let(:hash) do
      Concierge::SafeAccessHash.new(
        "@id" => 1450,
        "country_name" => "New Country"
      )
    end

    it "builds country entity from hash with proper attributes" do
      country = described_class.build(hash)
      expect(country).to be_kind_of(SAW::Entities::Country)
      expect(country.id).to eq(1450)
      expect(country.name).to eq("New Country")
    end
  end
end
