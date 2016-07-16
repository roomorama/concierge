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

  describe ".reverse_date" do
    it "is empty when there are no reservations" do
      expect(described_class.reverse_date.to_a).to eq []
    end

    it "orders the reservations bringing the most recent first" do
      old_reservation = create_reservation(created_at: Time.now - 3 * 34 * 60 * 60) # three days ago
      new_reservation = create_reservation

      expect(described_class.reverse_date.to_a).to eq [new_reservation, old_reservation]
    end
  end
end
