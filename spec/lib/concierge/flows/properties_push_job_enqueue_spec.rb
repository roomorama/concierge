require "spec_helper"

RSpec.describe Concierge::Flows::PropertiesPushJobEnqueue do
  subject { described_class.new([1, 2]) }
  it "sends the right message" do
    expect_any_instance_of(Concierge::Queue).
      to receive(:add) do |queue, element|
      expect(element.operation).to eq "properties_push"
      expect(element.data).to eq({ ids: [1, 2] })
    end
    subject.call
  end
end

