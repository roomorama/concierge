require "spec_helper"

RSpec.describe SAW::Commands::BaseFetcher do
  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }

  context "#valid_result?" do
    it "returns false if there is no response tag in the given response" do
      response = Concierge::SafeAccessHash.new(foo: "bar")

      validity = subject.valid_result?(response)
      expect(validity).to be false
    end

    it "returns true if there is no any response.errors in the given response" do
      response = Concierge::SafeAccessHash.new(response: {})

      validity = subject.valid_result?(response)
      expect(validity).to be true
    end

    it "returns false if there is existing error in the given response" do
      response = Concierge::SafeAccessHash.new(
        response: { errors: { code: '1000' }}
      )

      validity = subject.valid_result?(response)
      expect(validity).to be false
    end

    it "returns true if there is the error from white-listed codes" do
      response = Concierge::SafeAccessHash.new(
        response: { errors: { error: { code: '1007' }}}
      )

      validity = subject.valid_result?(response)
      expect(validity).to be true
    end
  end
end
