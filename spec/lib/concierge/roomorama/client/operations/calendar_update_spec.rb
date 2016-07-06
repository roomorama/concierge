require "spec_helper"

RSpec.describe Roomorama::Client::Operations::CalendarUpdate do
  let(:property) { }

  subject { described_class.new(property) }

  describe "#endpoint" do
    it "knows the endpoint to update availabilities" do
      expect(subject.endpoint).to eq "/v1.0/host/rooms/1/availabilities"
    end
  end

  describe "#method" do
    it "knows the request method to update availabilities" do
      expect(subject.request_method).to eq :put
    end
  end

  describe "#request_data"
end
