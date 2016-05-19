require "spec_helper"

RSpec.describe Web::Support::Authentication do
  let(:env_name)    { "CONCIERGE_WEB_AUTHENTICATION" }
  let(:credentials) { "admin:admin" }

  around do |example|
    ENV[env_name] = credentials
    example.run
    ENV.delete(env_name)
  end

  describe "#authorized?" do
    it "is unauthorized if username and password are not given" do
      expect(described_class.new("admin", nil)).not_to be_authorized
      expect(described_class.new(nil, "admin")).not_to be_authorized
      expect(described_class.new(nil, nil)).not_to be_authorized
    end

    it "is unauthorized if the username does not match" do
      expect(described_class.new("invalid", "admin")).not_to be_authorized
    end

    it "is unauthorized if the password does not match" do
      expect(described_class.new("admin", "invalid")).not_to be_authorized
    end

    it "is authorized if the username and password match" do
      expect(described_class.new("admin", "admin")).to be_authorized
    end
  end
end
