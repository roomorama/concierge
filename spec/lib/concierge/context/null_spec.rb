require "spec_helper"

RSpec.describe Concierge::Context::Null do
  it "has an empty list of events" do
    expect(subject.events).to eq []
  end

  it "allows augmenting of the context to no effect" do
    event = Concierge::Context::Message.new(
      label:     "Test Message",
      message:   "Something occurred",
      backtrace: []
    )

    subject.augment(event)
    expect(subject.events).to eq []
  end

  it "has an empty hash representation" do
    expect(subject.to_h).to eq({})
  end
end
