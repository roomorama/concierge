require 'spec_helper'

module RentalsUnited
  RSpec.describe Converters::CheckInOutFees do
    let(:late_arrival_fees) do
      [
        { amount: 10.0, from: "13:00", to: "14:00" },
        { amount: 20.0, from: "14:00", to: "15:00" }
      ]
    end

    let(:early_departure_fees) do
      [
        { amount: 45.0, from: "14:00", to: "15:00" },
        { amount: 67.0, from: "17:00", to: "18:00" }
      ]
    end

    let(:ru_property_hash) do
      {
        id:                      "519688",
        title:                   "Test Property",
        lat:                     55.0003426,
        lng:                     73.2965942999999,
        address:                 "Test street address",
        postal_code:             "644119",
        max_guests:              2,
        bedroom_type_id:         "4",
        property_type_id:        "35",
        active:                  true,
        archived:                false,
        surface:                 39,
        owner_id:                "378000",
        security_deposit_type:   "5",
        security_deposit_amount: 5.50,
        check_in_time:           "13:00-17:00",
        check_out_time:          "11:00",
        check_in_instructions:   "Some instructions",
        floor:                   5,
        description:             "Test Description",
        images:                  [],
        amenities:               [],
        number_of_bathrooms:     22,
        number_of_single_beds:   5,
        number_of_double_beds:   7,
        number_of_sofa_beds:     9,
        late_arrival_fees:       late_arrival_fees,
        early_departure_fees:    early_departure_fees
      }
    end

    let(:ru_property) { RentalsUnited::Entities::Property.new(ru_property_hash) }
    let(:currency) { "EUR" }
    let(:subject) { described_class.new(ru_property, currency) }

    it "converts fee rules to hash" do
      expect(subject.build_tranlations).to eq(
        {
          en: "* Late arrival fees:\n-  14:00 - 15:00 : 20.0 EUR\n-  13:00 - 14:00 : 10.0 EUR\n* Early departure fees:\n-  17:00 - 18:00 : 67.0 EUR\n-  14:00 - 15:00 : 45.0 EUR",
          zh: "* 晚到费用:\n-  14:00 - 15:00 : 20.0 EUR\n-  13:00 - 14:00 : 10.0 EUR\n* 提早离店费用:\n-  17:00 - 18:00 : 67.0 EUR\n-  14:00 - 15:00 : 45.0 EUR",
          de: "* Gebühren für späte Ankunft:\n-  14:00 - 15:00 : 20.0 EUR\n-  13:00 - 14:00 : 10.0 EUR\n* Gebühren für frühe Abreise:\n-  17:00 - 18:00 : 67.0 EUR\n-  14:00 - 15:00 : 45.0 EUR",
          es: "* Penalización por retraso en la llegada:\n-  14:00 - 15:00 : 20.0 EUR\n-  13:00 - 14:00 : 10.0 EUR\n* La comisión a aplicar por salida anticipada:\n-  17:00 - 18:00 : 67.0 EUR\n-  14:00 - 15:00 : 45.0 EUR"
        }
      )
    end

    context "when there is only late fees" do
      let(:early_departure_fees) { [] }

      it "converts fee rules to text when there is no late fees" do
        expect(subject.build_tranlations).to eq(
          {
            en: "* Late arrival fees:\n-  14:00 - 15:00 : 20.0 EUR\n-  13:00 - 14:00 : 10.0 EUR",
            zh: "* 晚到费用:\n-  14:00 - 15:00 : 20.0 EUR\n-  13:00 - 14:00 : 10.0 EUR",
            de: "* Gebühren für späte Ankunft:\n-  14:00 - 15:00 : 20.0 EUR\n-  13:00 - 14:00 : 10.0 EUR",
            es: "* Penalización por retraso en la llegada:\n-  14:00 - 15:00 : 20.0 EUR\n-  13:00 - 14:00 : 10.0 EUR"
          }
        )
      end
    end

    context "when there is only early fees" do
      let(:late_arrival_fees) { [] }

      it "converts fee rules to text when there is no late fees" do
        expect(subject.build_tranlations).to eq(
          {
            en: "* Early departure fees:\n-  17:00 - 18:00 : 67.0 EUR\n-  14:00 - 15:00 : 45.0 EUR",
            zh: "* 提早离店费用:\n-  17:00 - 18:00 : 67.0 EUR\n-  14:00 - 15:00 : 45.0 EUR",
            de: "* Gebühren für frühe Abreise:\n-  17:00 - 18:00 : 67.0 EUR\n-  14:00 - 15:00 : 45.0 EUR",
            es: "* La comisión a aplicar por salida anticipada:\n-  17:00 - 18:00 : 67.0 EUR\n-  14:00 - 15:00 : 45.0 EUR"
          }
        )
      end
    end

    context "when there is no fees" do
      let(:late_arrival_fees) { [] }
      let(:early_departure_fees) { [] }

      it "returns nil" do
        expect(subject.build_tranlations).to eq(nil)
      end
    end
  end
end
