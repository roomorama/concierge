require 'spec_helper'

module RentalsUnited
  RSpec.describe Entities::Rate do
    let(:attributes) do
      {
        date_from: Date.parse("2016-09-01"),
        date_to:   Date.parse("2016-09-15"),
        price:     "200.00"
      }
    end

    let(:rate) { Entities::Rate.new(attributes) }

    describe "has_price_for_date?" do
      it "returns true when given date is between from and to dates" do
        date = Date.parse("2016-09-04")
        expect(rate.has_price_for_date?(date)).to eq(true)
      end

      it "returns true when given date matches to date_from" do
        date = Date.parse("2016-09-01")
        expect(rate.has_price_for_date?(date)).to eq(true)
      end

      it "returns true when given date matches to date_to" do
        date = Date.parse("2016-09-15")
        expect(rate.has_price_for_date?(date)).to eq(true)
      end

      it "returns false when given date is less than date_from" do
        date = Date.parse("2016-08-15")
        expect(rate.has_price_for_date?(date)).to eq(false)
      end

      it "returns false when given date is greater than date_to" do
        date = Date.parse("2016-09-16")
        expect(rate.has_price_for_date?(date)).to eq(false)
      end
    end
  end
end
