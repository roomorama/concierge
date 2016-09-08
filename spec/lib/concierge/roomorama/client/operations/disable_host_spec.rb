require "spec_helper"

RSpec.describe Roomorama::Client::Operations::DisableHost do

  describe "#endpoint" do
    it "knows the endpoint where a host can be disabled" do
      expect(subject.endpoint).to eq "/v1.0/disable-host"
    end
  end

  describe "#method" do
    it "knows the request method to be used" do
      expect(subject.request_method).to eq :put
    end
  end
end
