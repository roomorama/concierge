require "spec_helper"

RSpec.describe RentalsUnited::PayloadBuilder do
  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:builder) { described_class.new(credentials) }

  describe '#build_property_ids_fetch_payload' do
    let(:params) do
      {
        location_id: "123"
      }
    end

    it 'embedds username and password to request' do
      xml = builder.build_property_ids_fetch_payload(params[:location_id])
      hash = to_hash(xml)

      authentication = hash.get("Pull_ListProp_RQ.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end

    it 'adds location_id to request' do
      xml = builder.build_property_ids_fetch_payload(params[:location_id])
      hash = to_hash(xml)

      location_id = hash.get("Pull_ListProp_RQ.LocationID")
      expect(location_id).to eq(params[:location_id])
    end
  end

  describe '#build_cities_fetch_payload' do
    it 'embedds username and password to request' do
      xml = builder.build_cities_fetch_payload
      hash = to_hash(xml)

      authentication = hash.get("Pull_ListCitiesProps_RQ.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end
  end

  describe '#build_property_ids_fetch_payload' do
    let(:params) do
      {
        property_id: "123"
      }
    end

    it 'embedds username and password to request' do
      xml = builder.build_property_fetch_payload(params[:property_id])
      hash = to_hash(xml)

      authentication = hash.get("Pull_ListSpecProp_RQ.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end

    it 'adds property_id to request' do
      xml = builder.build_property_fetch_payload(params[:property_id])
      hash = to_hash(xml)

      property_id = hash.get("Pull_ListSpecProp_RQ.PropertyID")
      expect(property_id).to eq(params[:property_id])
    end
  end

  private
  def to_hash(xml)
    Concierge::SafeAccessHash.new(Nori.new.parse(xml))
  end
end
