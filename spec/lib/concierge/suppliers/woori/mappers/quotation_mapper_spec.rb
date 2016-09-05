require 'spec_helper'

module Woori
  RSpec.describe Mappers::Quotation do
    include Concierge::JSON
    include Support::Fixtures

    let(:quotation_attrs) do
      {
        property_id: '123',
        unit_id: '321',
        check_in: '10/05/2016',
        check_out: '11/05/2016',
        guests: 1
      }
    end

    let(:quotation_params) { Concierge::SafeAccessHash.new(quotation_attrs) }

    it "builds Quotation object" do
      unit_rate_params = decoded_fixture("woori/unit_rates/success.json")
      mapper = described_class.new(quotation_params, unit_rate_params)
      quotation = mapper.build

      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.property_id).to eq(quotation_attrs[:property_id])
      expect(quotation.unit_id).to eq(quotation_attrs[:unit_id])
      expect(quotation.check_in).to eq(quotation_attrs[:check_in])
      expect(quotation.check_out).to eq(quotation_attrs[:check_out])
      expect(quotation.guests).to eq(quotation_attrs[:guests])
    end

    it "calculates total price for Quotation" do
      unit_rate_params = decoded_fixture("woori/unit_rates/price_calc.json")
      mapper = described_class.new(quotation_params, unit_rate_params)
      quotation = mapper.build

      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.available).to be true
      expect(quotation.currency).to eq("KRW")
      expect(quotation.total).to eq(60012.0)
    end

    it "makes quotation unavailable if at least one day has no vacancy" do
      unit_rate_params = decoded_fixture("woori/unit_rates/no_vacancy.json")
      mapper = described_class.new(quotation_params, unit_rate_params)
      quotation = mapper.build

      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.available).to be false
    end

    it "makes quotation unavailable if at least one day has negative vacancy" do
      unit_rate_params = decoded_fixture("woori/unit_rates/negative_vacancy.json")
      mapper = described_class.new(quotation_params, unit_rate_params)
      quotation = mapper.build

      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.available).to be false
    end

    it "makes quotation unavailable if at least one day has no active" do
      unit_rate_params = decoded_fixture("woori/unit_rates/not_active.json")
      mapper = described_class.new(quotation_params, unit_rate_params)
      quotation = mapper.build

      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.available).to be false
    end

    it "makes quotation available if all days are active and has vacancy" do
      unit_rate_params = decoded_fixture("woori/unit_rates/available.json")
      mapper = described_class.new(quotation_params, unit_rate_params)
      quotation = mapper.build

      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.available).to be true
    end

    private
    def decoded_fixture(path)
      json = read_fixture(path)
      result = json_decode(json)
      Concierge::SafeAccessHash.new(result.value)
    end
  end
end
