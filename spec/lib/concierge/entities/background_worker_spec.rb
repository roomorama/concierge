require "spec_helper"

RSpec.describe BackgroundWorker do
  describe "#running?" do
    it "is running when the status indicates so" do
      subject.status = "running"
      expect(subject).to be_running
    end

    it "is not running when idle" do
      subject.status = "idle"
      expect(subject).not_to be_running
    end
  end

  describe "#idle?" do
    it "is idle when the status indicates so" do
      subject.status = "idle"
      expect(subject).to be_idle
    end

    it "is not running when running" do
      subject.status = "running"
      expect(subject).not_to be_idle
    end
  end
end
