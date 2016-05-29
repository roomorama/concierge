require "spec_helper"

RSpec.describe Workers::Router do
  before do
    host = Host.new(
      supplier_id:  1,
      identifier:   "supplier1",
      username:     "supplier",
      access_token: "abc123"
    )

    HostRepository.create(host)
  end

  let(:attributes) {
    {
      title: "Studio Apartment",
      description: "Largest Apartment in New York",
      nightly_rate: 100,
      weekly_rate: 200,
      monthly_rate: 300,

      images: [
        {
          identifier: "img1",
          url:        "https://www.example.org/img1",
        },
        {
          identifier: "img2",
          url:        "https://www.example.org/img2",
          caption:    "Swimming Pool"
        }
      ],

      availabilities: {
        start_date: "2016-05-23",
        data:       "0101010000"
      }
    }
  }

  let(:roomorama_property) { Roomorama::Property.load(attributes) }

  subject { described_class.new(host) }

  describe "#dispatch" do
    it "enqueues a publish operation in case the property was not previously imported" do
      generated = nil
      expect(subject).to receive(:enqueue) { |operation| generated = operation }

      subject.dispatch(roomorama_property)
      expect(generated).to be_a Roomorama::Client::Operations::Publish
      expect(generated.property).to eq roomorama_property
    end
  end
end
