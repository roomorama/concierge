require 'spec_helper'

module Woori
  RSpec.describe Mappers::ReservationStatus do
    include Concierge::JSON
    include Support::Fixtures

    let(:pending_reservation_hash) do
      json = read_fixture("woori/entities/reservation_status/pending.json")
      result = json_decode(json)
      result.value
    end

    let(:confirmed_reservation_hash) do
      json = read_fixture("woori/entities/reservation_status/confirmed.json")
      result = json_decode(json)
      result.value
    end

    it "builds pending reservation status object" do
      safe_hash = Concierge::SafeAccessHash.new(pending_reservation_hash)
      mapper = described_class.new(safe_hash)
      reservation_status = mapper.build_reservation_status
      expect(reservation_status).to be_kind_of(Entities::ReservationStatus)
      expect(reservation_status.reservation_code).to eq(
        "w_WP20160729112634CD7D"
      )
      expect(reservation_status.status).to eq("pending")
    end

    it "builds confirmed reservation status object" do
      safe_hash = Concierge::SafeAccessHash.new(confirmed_reservation_hash)
      mapper = described_class.new(safe_hash)
      reservation_status = mapper.build_reservation_status
      expect(reservation_status).to be_kind_of(Entities::ReservationStatus)
      expect(reservation_status.reservation_code).to eq(
        "w_WP20160729141224FE3E"
      )
      expect(reservation_status.status).to eq("confirmed")
    end
  end
end
