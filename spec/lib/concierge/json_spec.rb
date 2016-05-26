require "spec_helper"

RSpec.describe Concierge::JSON do
  include Concierge::JSON

  describe "#json_encode" do
    it "transforms data to a valid JSON representation" do
      data = { success: true }
      expect(json_encode(data)).to eq %({"success":true})
    end
  end

  describe "#json_decode" do
    it "returns an error result in case the content is not a valid JSON string" do
      result = json_decode("invalid-json")

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it "anounces parse errors" do
      error = Struct.new(:message).new

      Concierge::Announcer.on(Concierge::JSON::PARSING_ERROR) do |message|
        error.message = message
      end

      json_decode("invalid-json")
      expect(error.message).to match /lexical error: invalid char in json text/
    end
  end
end
