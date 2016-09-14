require 'spec_helper'

module SAW
  RSpec.describe Mappers::PropertyRate do
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

    it "builds available property rate object" do
      property_rate = described_class.build(hash)
      expect(property_rate).to be_kind_of(SAW::Entities::PropertyRate)
      expect(property_rate.id).to eq("2596")
      expect(property_rate.currency).to eq("EUR")
      expect(property_rate.units.size).to eq(1)

      unit = property_rate.units.first

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

      it "returns nil object" do
        property_rate = described_class.build(hash)

        expect(property_rate).to be_nil
      end
    end
  end
end
