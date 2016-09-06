require 'spec_helper'

module RentalsUnited
  RSpec.describe Converters::CountryCode do
    it "returns country code by its name" do
      code = described_class.code_by_name("Kuwait")
      expect(code).to eq("KW")
    end
  end
end
