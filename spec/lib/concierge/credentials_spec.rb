require "spec_helper"

RSpec.describe Credentials do
  let(:name) { "Supplier" }

  class Credentials
    def self.reset!
      @_data = nil
    end
  end

  before do
    Credentials.reset!
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
  end

  describe ".validate_credentials!" do
    it "raises an exception if given a supplier that is not defined" do
      expect {
        Credentials.validate_credentials!({
          "unknown_supplier" => ["username", "password"]
        })
      }.to raise_error(Credentials::MissingSupplierError)
    end

    it "raises an error in case a required credential is not defined" do
      expect {
        Credentials.validate_credentials!({
          "supplier" => ["username", "password", "unknown_credential"]
        })
      }.to raise_error(Credentials::MissingCredentialError)
    end

    it "raises an error if a required credential is empty" do
      expect {
        Credentials.validate_credentials!({
          "supplier" => ["username", "password", "token"]
        })
      }.to raise_error(Credentials::MissingCredentialError)
    end

    it "is successful if all required credentials are defined" do
      ENV["_TEST_PARTNER_TOKEN"] = "abc123"

      expect {
        Credentials.validate_credentials!({
          "supplier" => ["username", "password", "token"]
        })
      }.not_to raise_error

      ENV["_TEST_PARTNER_TOKEN"] = nil
    end
  end
end
