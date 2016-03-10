require "spec_helper"

RSpec.describe Concierge::Announcer do
  class TestCallable
    attr_reader :called

    def initialize
      @called = false
    end

    def call
      @called = true
    end

    def called?
      called
    end

    def to_proc
      -> { self.call }
    end
  end

  describe "#on" do
    it "associates a callable to a given event" do
      subject.on("event", &TestCallable.new)

      listeners = subject.listeners["event"]
      expect(listeners.size).to eq 1
    end
  end

  describe "#trigger" do
    it "does nothing if there is no listener" do
      expect(subject.trigger("unlistened_to_event")).to be
    end

    it "calls each listener in order of subscription" do
      listener1 = TestCallable.new
      listener2 = TestCallable.new

      subject.on("event", &listener1)
      subject.on("event", &listener2)
      subject.trigger("event")

      expect(listener1).to be_called
      expect(listener2).to be_called
    end

    it "passes arguments to listeners" do
      called = nil
      subject.on("event") { |val:| called = val }

      subject.trigger("event", val: 42)
      expect(called).to eq 42
    end

    it "does not trigger listeners from other events" do
      listener1 = TestCallable.new
      listener2 = TestCallable.new

      subject.on("event", &listener1)
      subject.on("another_event", &listener2)
      subject.trigger("event")

      expect(listener1).to be_called
      expect(listener2).not_to be_called
    end
  end

  describe "class methods" do
    it "delegates `on` to an instance" do
      listener = TestCallable.new

      expect(Concierge::Announcer._announcer).to receive(:on).with("an_event")
      Concierge::Announcer.on("an_event", &listener)
    end

    it "delegates `trigger` to an instance" do
      listener = TestCallable.new

      expect(Concierge::Announcer._announcer).to receive(:trigger).with("an_event", 1, 2, 3)
      Concierge::Announcer.trigger("an_event", 1, 2, 3)
    end
  end

end
