require "spec_helper"

RSpec.describe Workers::Suppliers::Waytostay do
  include Support::Factories
  include Support::Fixtures

  let(:changes) { {
    properties:   ["001", "002"],
    media:        [], #["003", "004"],
    availability: [], #["005", "001"],
    rates:        [], #["001", "005"],
    bookings:     []
  }}
  before do
    allow(subject.remote).to receive(:get_changes_since).and_return(changes)
    # properties 001 and 002 is stubbed from remote, 003, 004 and 005 stubbed from concierge database
    allow(subject.remote).to receive(:get_property) do |ref|
      expect(["001", "002"]).to include ref
      Roomorama::Property.load(
        Concierge::SafeAccessHash.new(
          JSON.parse(read_fixture("waytostay/properties/#{ref}.roomorama-attributes.json"))
        )
      )
    end
  end

  subject { described_class.new(create_host) }

  describe "perform" do
    it "should start property attributes synchronisation" do
      expect{
        expect(subject.synchronisation.router).to receive(:dispatch)
          .exactly(changes[:properties].count).times
        subject.perform
      }.to_not raise_error
    end
  end
end

