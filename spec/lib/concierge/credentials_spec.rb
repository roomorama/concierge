require "spec_helper"

RSpec.describe Concierge::Credentials do
  let(:name) { "Supplier" }

  class Concierge::Credentials
    def self.reset!
      @_data = nil
    end
  end

  before do
    Concierge::Credentials.reset!
  end

  describe ".for" do
    it "returns the information declared in the credentials file" do
      credentials = described_class.for(name)

      expect(credentials.username).to eq "roomorama"
      expect(credentials.password).to eq "p4ssw0rd"
      expect(credentials.token).to be_nil
    end

    it "uses environment variables if defined" do
      ENV["_TEST_PARTNER_TOKEN"] = "abc123"
      credentials = described_class.for(name)

      expect(credentials.token).to eq "abc123"
      ENV["_TEST_PARTNER_TOKEN"] = nil
    end

    it "raises an error if there are no credentials registered" do
      expect {
        described_class.for("invalid_credentials")
      }.to raise_error Concierge::Credentials::NoCredentialsError
    end
  end

  describe ".validate_credentials!" do
    it "raises an exception if given a supplier that is not defined" do
      expect {
        Concierge::Credentials.validate_credentials!({
          "unknown_supplier" => ["username", "password"]
        })
      }.to raise_error(Concierge::Credentials::MissingSupplierError)
    end

    it "raises an error in case a required credential is not defined" do
      expect {
        Concierge::Credentials.validate_credentials!({
          "supplier" => ["username", "password", "unknown_credential"]
        })
      }.to raise_error(Concierge::Credentials::MissingCredentialError)
    end

    it "raises an error if a required credential is empty" do
      expect {
        Concierge::Credentials.validate_credentials!({
          "supplier" => ["username", "password", "token"]
        })
      }.to raise_error(Concierge::Credentials::MissingCredentialError)
    end

    it "is successful if all required credentials are defined" do
      ENV["_TEST_PARTNER_TOKEN"] = "abc123"

      expect {
        Concierge::Credentials.validate_credentials!({
          "supplier" => ["username", "password", "token", "test_mode"]
        })
      }.not_to raise_error

      ENV["_TEST_PARTNER_TOKEN"] = nil
    end
  end
end
