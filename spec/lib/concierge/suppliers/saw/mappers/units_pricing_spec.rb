require 'spec_helper'

module SAW
  RSpec.describe Mappers::UnitsPricing do
    let(:attributes) do
      {
        "name"=>"Adagio Access Avignon",
        "check_in"=>"01/09/2016",
        "check_out"=>"02/09/2016",
        "currency_code"=>"EUR",
        "default_currency_code"=>"EUR",
        "apartments"=> {
          "accommodation_type" => {
            "property_accommodation" => {
              "property_accommodation_name" => "Apartment 1 bedroom for 4 people ",
              "number_of_guests"=>"1",
              "maximum_guests"=>"4",
              "bed_types"=>nil,
              "status"=> {
                "flag_fair_warning"=>"N",
                "flag_no_allocation"=>"N",
                "flag_free_sale"=>"Y",
                "flag_great_deal"=>"N"
              },
              "flag_dynamic"=>"Y",
              "price_detail"=> {
                "net" => {
                  "date_range"=>{
                    "date_info"=>{
                      "date"=>"01/09/2016",
                      "price"=>"104"
                    }
                  },
                  "average_price"=>{"price"=>"104.00"},
                  "total_price"=>{"price"=>"104.00"}
                },
                "rate_plans"=>{
                  "rate_plan_code"=>nil,
                  "condition_type"=>nil,
                  "cancellation_policies"=>nil
                }
              },
              "flag_bookable_property_accommodation"=>"Y",
              "@id"=>"9863"
            },
            "@id"=>"-1"
          }
        },
        "thirtyday_rates"=>"N",
        "flag_supported_currency"=>"Y",
        "flag_payable_currency"=>"Y",
        "flag_bookable_property"=>"Y",
        "flag_breakfast_included"=>"N",
        "affiliate_message"=>nil,
        "cancellation_message"=>"A cancellation period of 5 days applies",
        "cancellation_days"=>"5",
        "payment_notice"=>nil,
        "propertyimportantpoints"=>nil,
        "@id"=>"2596"
      }
    end

    let(:hash) { Concierge::SafeAccessHash.new(attributes) }
    let(:rates_array) { Array(hash) }
    let(:stay_length) { 1 }

    it "builds available property rate object" do
      units_pricings = described_class.build(rates_array, stay_length)
      expect(units_pricings).to be_kind_of(Array)
      expect(units_pricings.size).to eq(1)
      expect(units_pricings).to all(be_kind_of(SAW::Entities::UnitsPricing))

      units_pricing = units_pricings.first
      expect(units_pricing.property_id).to eq("2596")
      expect(units_pricing.currency).to eq("EUR")
      expect(units_pricing.units.size).to eq(1)

      unit = units_pricing.units.first

      expect(unit.id).to eq("9863")
      expect(unit.price).to eq(104.00)
      expect(unit.available).to eq(true)
      expect(unit.max_guests).to eq(4)
    end

    describe "when rates are not available" do
      let(:attributes) do
        {
          "name"=>"Adagio Access Avignon",
          "check_in"=>"01/09/2016",
          "check_out"=>"02/09/2016",
          "currency_code"=>"EUR",
          "default_currency_code"=>"EUR",
          "apartments"=> {}
        }
      end

      it "returns an empty array" do
        units_pricing = described_class.build(rates_array, stay_length)

        expect(units_pricing).to eq([])
      end
    end

    describe "when rates are fetched for a few days" do
      let(:stay_length) { 3 }

      it "divide total price to stay_length value" do
        units_pricings = described_class.build(rates_array, stay_length)
        expect(units_pricings).to be_kind_of(Array)
        expect(units_pricings.size).to eq(1)
        expect(units_pricings).to all(be_kind_of(SAW::Entities::UnitsPricing))

        units_pricing = units_pricings.first
        expect(units_pricing.property_id).to eq("2596")
        expect(units_pricing.currency).to eq("EUR")
        expect(units_pricing.units.size).to eq(1)

        unit = units_pricing.units.first

        expect(unit.id).to eq("9863")
        expect(unit.price).to eq(34.67)
        expect(unit.available).to eq(true)
        expect(unit.max_guests).to eq(4)
      end
    end
  end
end
