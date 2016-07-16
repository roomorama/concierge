require "spec_helper"

RSpec.describe ReservationRepository do
  include Support::Factories

  describe ".count" do
    it "is zero when there are no records in the database" do
      expect(described_class.count).to eq 0
    end

    it "increases when new records are added" do
      create_reservation
      expect(described_class.count).to eq 1
    end
  end
end
