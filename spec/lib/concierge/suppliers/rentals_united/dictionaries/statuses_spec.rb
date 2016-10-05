require 'spec_helper'

module RentalsUnited
  RSpec.describe Dictionaries::Statuses do
    let(:supported_error_codes) { 0..130 }

    it "finds error description" do
      message = described_class.find("118")
      expect(message).to eq("Max number of guests must be of positive value.")
    end

    it "finds descriptions for all supported error codes" do
      supported_error_codes.each do |error_code|
        expect(described_class.find(error_code.to_s)).not_to be_nil
      end
    end
  end
end
