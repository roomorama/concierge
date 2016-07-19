require "spec_helper"

RSpec.describe Roomorama::Client::Operations::UpdateCalendar do
  let(:calendar) { Roomorama::Calendar.new("JPN123") }

  subject { described_class.new(calendar) }

  describe "#endpoint" do
    it "knows the endpoint where a property can be published" do
      expect(subject.endpoint).to eq "/v1.0/host/update_calendar"
    end
  end

  describe "#method" do
    it "knows the request method to be used when publishing" do
      expect(subject.request_method).to eq :put
    end
  end

  describe "#request_data" do
    it "calls the +to_h+ method of the underlying property" do
      expect(calendar).to receive(:to_h)
      subject.request_data
    end
  end
end
