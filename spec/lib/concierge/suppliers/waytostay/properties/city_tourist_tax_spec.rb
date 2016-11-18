require 'spec_helper'

RSpec.describe Waytostay::Properties::CityTouristTax do
  let(:currency) { "EUR" }

  context "included already" do
    let(:taxes) {
      [
        {
          "included"   => true,
          "rate"       => 17,
          "rate_type"  => "per_stay",
          "from_age"   => 18,
          "max_nights" => 0
        }
      ]
    }
    it "should be correct" do
      tax_in_words = described_class.new(taxes, currency).parse
      expect(tax_in_words[:en]).to eq ""
      expect(tax_in_words[:de]).to eq ""
      expect(tax_in_words[:es]).to eq ""
      expect(tax_in_words[:zh]).to eq ""
      expect(tax_in_words[:zh_tw]).to eq ""
    end
  end
  context "of type per_stay" do
    let(:taxes) {
      [
        {
          "included"   => false,
          "rate"       => 17,
          "rate_type"  => "per_stay",
          "from_age"   => 18,
          "max_nights" => 0
        }
      ]
    }

    it "should be correct" do
      tax_in_words = described_class.new(taxes, currency).parse
      expect(tax_in_words[:en]).to eq "Additional City Tourist Tax: 17 EUR will need to be paid at the property.\n"
      expect(tax_in_words[:de]).to eq "Zusätzliche Abgabe für Touristen in Höhe von 17 EUR wird direkt beim Gastgeber bezahlt.\n"
      expect(tax_in_words[:es]).to eq "Impuesto municipal de turismo adicional: 17 EUR tendrá que ser pagado en la propieda.\n"
      expect(tax_in_words[:zh]).to eq "附加城市旅游税17 EUR，需到达酒店时支付\n"
      expect(tax_in_words[:zh_tw]).to eq "附加城市旅游税17 EUR，需到達酒店時支付\n"
    end
  end

  context "of type per_night" do
    let(:taxes) {
      [
        {
          "included"   => false,
          "rate"       => 13,
          "rate_type"  => "per_night",
          "from_age"   => 18,
          "max_nights" => 10
        }
      ]
    }

    it "should be correct" do
      tax_in_words = described_class.new(taxes, currency).parse
      expect(tax_in_words[:en]).to eq "Additional City Tourist Tax: 13 EUR per night will need to be paid at the property for up to 10 nights.\n"
      expect(tax_in_words[:de]).to eq "Zusätzliche Abgabe für Touristen in Höhe von 13 EUR pro Nacht wird direkt beim Gastgeber bezahlt, für bis zu 10 Nächte.\n"
      expect(tax_in_words[:es]).to eq "Impuesto municipal de turismo adicional: 13 EUR por noche tendrá que ser pagado en la propieda para un máximo de 10 noche.\n"
      expect(tax_in_words[:zh]).to eq "附加城市旅游税13 EUR 每晚，需到达酒店时支付最多10晚\n"
      expect(tax_in_words[:zh_tw]).to eq "附加城市旅游税13 EUR 每晚，需到達酒店時支付最多10晚\n"
    end
  end

  context "of type per_night with max_night=0" do
    let(:taxes) {
      [
        {
          "included"   => false,
          "rate"       => 13,
          "rate_type"  => "per_night",
          "from_age"   => 18,
          "max_nights" => 0
        }
      ]
    }

    it "should be correct" do
      tax_in_words = described_class.new(taxes, currency).parse
      expect(tax_in_words[:en]).to eq "Additional City Tourist Tax: 13 EUR per night will need to be paid at the property.\n"
      expect(tax_in_words[:de]).to eq "Zusätzliche Abgabe für Touristen in Höhe von 13 EUR pro Nacht wird direkt beim Gastgeber bezahlt.\n"
      expect(tax_in_words[:es]).to eq "Impuesto municipal de turismo adicional: 13 EUR por noche tendrá que ser pagado en la propieda.\n"
      expect(tax_in_words[:zh]).to eq "附加城市旅游税13 EUR 每晚，需到达酒店时支付\n"
      expect(tax_in_words[:zh_tw]).to eq "附加城市旅游税13 EUR 每晚，需到達酒店時支付\n"
    end
  end

  context "of type per_person_per_night" do
    let(:taxes) {
      [
        {
          "included"   => false,
          "rate"       => 0.83,
          "rate_type"  => "per_person_per_night",
          "from_age"   => 18,
          "max_nights" => 10
        }
      ]
    }

    it "should be correct" do
      tax_in_words = described_class.new(taxes, currency).parse
      expect(tax_in_words[:en]).to eq "Additional City Tourist Tax: 0.83 EUR per night per person will need to be paid at the property for guests above 18 years of age for up to 10 nights.\n"
      expect(tax_in_words[:de]).to eq "Zusätzliche Abgabe für Touristen in Höhe von 0.83 EUR pro Nacht, pro Person wird direkt beim Gastgeber bezahlt, für Gäste älter als 18 Jahre, für bis zu 10 Nächte.\n"
      expect(tax_in_words[:es]).to eq "Impuesto municipal de turismo adicional: 0.83 EUR por noche tendrá que ser pagado en la propieda para un máximo de 10 noche.\n"
      expect(tax_in_words[:zh]).to eq "超过18岁的客人，附加城市旅游税0.83 EUR每人，每晚需到达酒店时支付，最多10晚。\n"
      expect(tax_in_words[:zh_tw]).to eq "超过18岁的客人，附加城市旅游税0.83 EUR每人，每晚需到達酒店時支付，最多10晚。\n"
    end
  end

  context "of type per_person_per_night with max_nights=0" do
    let(:taxes) {
      [
        {
          "included"   => false,
          "rate"       => 0.83,
          "rate_type"  => "per_person_per_night",
          "from_age"   => 18,
          "max_nights" => 0
        }
      ]
    }

    it "should be correct" do
      tax_in_words = described_class.new(taxes, currency).parse
      expect(tax_in_words[:en]).to eq "Additional City Tourist Tax: 0.83 EUR per night per person will need to be paid at the property for guests above 18 years of age.\n"
      expect(tax_in_words[:de]).to eq "Zusätzliche Abgabe für Touristen in Höhe von 0.83 EUR pro Nacht, pro Person wird direkt beim Gastgeber bezahlt, für Gäste älter als 18 Jahre.\n"
      expect(tax_in_words[:es]).to eq "Impuesto municipal de turismo adicional: 0.83 EUR por noche tendrá que ser pagado en la propieda.\n"
      expect(tax_in_words[:zh]).to eq "超过18岁的客人，附加城市旅游税0.83 EUR每人，每晚需到达酒店时支付。\n"
      expect(tax_in_words[:zh_tw]).to eq "超过18岁的客人，附加城市旅游税0.83 EUR每人，每晚需到達酒店時支付。\n"
    end
  end

  context "of type percent_off_gross" do
    let(:taxes) {
      [
        {
          "included"   => false,
          "rate"       => 0.83,
          "rate_type"  => "percent_off_gross",
          "from_age"   => 18,
          "max_nights" => 0
        }
      ]
    }

    it "should be correct" do
      tax_in_words = described_class.new(taxes, currency).parse
      expect(tax_in_words[:en]).to eq "Additional City Tourist Tax: 0.83% of the total price will need to be paid at the property.\n"
      expect(tax_in_words[:de]).to eq "Zusätzliche Abgabe für Touristen in Höhe von 0.83% der Gesamtsumme wird direkt beim Gastgeber bezahlt.\n"
      expect(tax_in_words[:es]).to eq "Impuesto municipal de turismo adicional: 0.83% del precio total tendrá que ser pagado en la propiedad.\n"
      expect(tax_in_words[:zh]).to eq "附加城市旅游税：定单总额的0.83%会在酒店到付。\n"
      expect(tax_in_words[:zh_tw]).to eq "附加城市旅游税：定單總額的0.83%會在酒店到付。\n"
    end
  end

  context "of type percent_off_net" do
    let(:taxes) {
      [
        {
          "included"   => false,
          "rate"       => 0.83,
          "rate_type"  => "percent_off_net",
          "from_age"   => 18,
          "max_nights" => 0
        }
      ]
    }

    it "should be correct" do
      tax_in_words = described_class.new(taxes, currency).parse
      expect(tax_in_words[:en]).to eq"Additional City Tourist Tax: 0.83% of the nightly rates will need to be paid at the property.\n"
      expect(tax_in_words[:de]).to eq"Zusätzliche Abgabe für Touristen in Höhe von 0.83% der Preise pro Nacht wird direkt beim Gastgeber bezahlt.\n"
      expect(tax_in_words[:es]).to eq"Impuesto municipal de turismo adicional: 0.83% de las tarifas nocturnas tendrá que ser pagado en la propiedad.\n"
      expect(tax_in_words[:zh]).to eq "附加城市旅游税：每晚价格的0.83%会在酒店到付。\n"
      expect(tax_in_words[:zh_tw]).to eq "附加城市旅游税：每晚價格的0.83%會在酒店到付。\n"
    end
  end
end
