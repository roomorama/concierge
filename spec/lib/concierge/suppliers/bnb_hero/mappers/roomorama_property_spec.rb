require 'spec_helper'

RSpec.describe BnbHero::Mappers::RoomoramaProperty do
  include Support::Fixtures

  describe "#map" do
    let(:property_hash) { JSON.parse(read_fixture('bnb_hero/property.json')) }

    subject { described_class.new.map property_hash }

    it "should return a valid Roomorama::Property result" do
      expect(subject).to be_success
      expect(subject.result).to be_a Roomorama::Property

      expected_property = Roomorama::Property.load(
        Concierge::SafeAccessHash.new(
          JSON.parse(read_fixture("bnb_hero/property.roomorama-attributes.json"))
        )
      )
      expect(expected_property).to be_success
      expect(subject.result.to_h).to match expected_property.result.to_h
      expect(subject.result.identifier).to eq "1011"
      expect { subject.result.validate! }.to_not raise_error
      expect(subject.result.default_to_available).to be_truthy
      expect(subject.result.multi_unit).to be_falsey
      expect(subject.result.instant_booking).to eq false
    end
  end

  describe "#type_and_subtype" do
    subject { described_class.new.send(:type_and_subtype, data) }

    context "bed_and_breakfast" do
      let(:data) { {"type" => "bed_and_breakfast", "subtype" => "bed_and_breakfast"} }
      it "parse as bnb" do
        expect(subject[:type]).to eq "bnb"
        expect(subject[:subtype]).to be_nil
      end
    end

    context "home_stay" do
      let(:data) { {"type" => "home_stay", "subtype" => "home_stay"} }
      it "parse as bnb" do
        expect(subject[:type]).to eq "bnb"
        expect(subject[:subtype]).to be_nil
      end
    end

    context "guest_house" do
      let(:data) { {"type" => "guest_house", "subtype" => "guest_house"} }
      it "parse as house" do
        expect(subject[:type]).to eq "house"
        expect(subject[:subtype]).to be_nil
      end
    end

    context "villa" do
      let(:data) { {"type" => "villa", "subtype" => "villa"} }
      it "parse as house-villa" do
        expect(subject[:type]).to eq "house"
        expect(subject[:subtype]).to eq "villa"
      end
    end

    context "hanok" do
      let(:data) { {"type" => "hanok", "subtype" => "hanok"} }
      it "parse as house" do
        expect(subject[:type]).to eq "house"
        expect(subject[:subtype]).to be_nil
      end
    end

    context "house" do
      let(:data) { {"type" => "house", "subtype" => "house"} }
      it "parse as house" do
        expect(subject[:type]).to eq "house"
        expect(subject[:subtype]).to be_nil
      end
    end

    context "apartment" do
      let(:data) { {"type" => "apartment", "subtype" => "apartment"} }
      it "parse as apartment" do
        expect(subject[:type]).to eq "apartment"
        expect(subject[:subtype]).to be_nil
      end
    end
  end

  describe "#rate" do
    let(:rates) { described_class.new.send(:rates, data) }
    let(:data) { {"nightly_rate" => 12.4,
                  "weekly_rate"  => 50.2,
                  "monthly_rate" => "null" } }
    it "should parse valid rates" do
      expect(rates[:nightly_rate]).to eq 12.4
      expect(rates[:weekly_rate]).to  eq 50.2
      expect(rates[:monthly_rate]).to eq 12.4 * 30
    end

  end

  describe "#sanitize!" do
    let(:sanitized) { described_class.new.send(:sanitize!, data) }
    let(:data) { {a: "false",
                  b: "true",
                  c: "null",
                  city: "서울시" } }

    it "cleans up bad json data" do
      expect(sanitized[:a]).to eq false
      expect(sanitized[:b]).to eq true
      expect(sanitized[:c]).to be_nil
    end
    it "rejects city name in korean" do
      expect(sanitized[:city]).to be_nil
    end
  end

end
