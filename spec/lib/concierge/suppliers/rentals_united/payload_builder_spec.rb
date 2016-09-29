require "spec_helper"

RSpec.describe RentalsUnited::PayloadBuilder do
  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }
  let(:builder) { described_class.new(credentials) }

  describe '#build_properties_collection_fetch_payload' do
    let(:params) do
      {
        owner_id: "123"
      }
    end

    it 'embedds username and password to request' do
      xml = builder.build_properties_collection_fetch_payload(
        params[:owner_id]
      )
      hash = to_hash(xml)

      authentication = hash.get("Pull_ListOwnerProp_RQ.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end

    it 'adds owner_id request' do
      xml = builder.build_properties_collection_fetch_payload(
        params[:owner_id]
      )
      hash = to_hash(xml)

      owner_id = hash.get("Pull_ListOwnerProp_RQ.OwnerID")
      expect(owner_id).to eq(params[:owner_id])
    end

    it 'adds include_nla flag to request' do
      xml = builder.build_properties_collection_fetch_payload(
        params[:owner_id]
      )
      hash = to_hash(xml)

      include_nla = hash.get("Pull_ListOwnerProp_RQ.IncludeNLA")
      expect(include_nla).to eq(false)
    end
  end

  describe '#build_owner_fetch_payload' do
    let(:params) do
      {
        owner_id: "123"
      }
    end

    it 'embedds username and password to request' do
      xml = builder.build_owner_fetch_payload(params[:owner_id])
      hash = to_hash(xml)

      authentication = hash.get("Pull_GetOwnerDetails_RQ.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end

    it 'adds owner_id request' do
      xml = builder.build_owner_fetch_payload(params[:owner_id])
      hash = to_hash(xml)

      owner_id = hash.get("Pull_GetOwnerDetails_RQ.OwnerID")
      expect(owner_id).to eq(params[:owner_id])
    end
  end

  describe '#build_locations_fetch_payload' do
    it 'embedds username and password to request' do
      xml = builder.build_locations_fetch_payload
      hash = to_hash(xml)

      authentication = hash.get("Pull_ListLocations_RQ.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end
  end

  describe '#build_location_currencies_fetch_payload' do
    it 'embedds username and password to request' do
      xml = builder.build_location_currencies_fetch_payload
      hash = to_hash(xml)

      authentication = hash.get("Pull_ListCurrenciesWithCities_RQ.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end
  end

  describe '#build_property_fetch_payload' do
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

  describe '#build_availabilities_fetch_payload' do
    let(:params) do
      {
        property_id: "123",
        date_from: "2016-09-01",
        date_to: "2017-09-01"
      }
    end

    let(:root_tag) { "Pull_ListPropertyAvailabilityCalendar_RQ" }

    it 'embedds username and password to request' do
      xml = builder.build_availabilities_fetch_payload(
        params[:property_id],
        params[:date_from],
        params[:date_to]
      )
      hash = to_hash(xml)

      authentication = hash.get("#{root_tag}.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end

    it 'adds property_id to request' do
      xml = builder.build_availabilities_fetch_payload(
        params[:property_id],
        params[:date_from],
        params[:date_to]
      )
      hash = to_hash(xml)

      property_id = hash.get("#{root_tag}.PropertyID")
      expect(property_id).to eq(params[:property_id])
    end

    it 'adds date range to request' do
      xml = builder.build_availabilities_fetch_payload(
        params[:property_id],
        params[:date_from],
        params[:date_to]
      )
      hash = to_hash(xml)

      date_from = hash.get("#{root_tag}.DateFrom")
      date_to   = hash.get("#{root_tag}.DateTo")
      expect(date_from.to_s).to eq(params[:date_from])
      expect(date_to.to_s).to eq(params[:date_to])
    end
  end

  describe '#build_seasons_fetch_payload' do
    let(:params) do
      {
        property_id: "123",
        date_from: "2016-09-01",
        date_to: "2017-09-01"
      }
    end

    let(:root_tag) { "Pull_ListPropertyPrices_RQ" }

    it 'embedds username and password to request' do
      xml = builder.build_seasons_fetch_payload(
        params[:property_id],
        params[:date_from],
        params[:date_to]
      )
      hash = to_hash(xml)

      authentication = hash.get("#{root_tag}.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end

    it 'adds property_id to request' do
      xml = builder.build_seasons_fetch_payload(
        params[:property_id],
        params[:date_from],
        params[:date_to]
      )
      hash = to_hash(xml)

      property_id = hash.get("#{root_tag}.PropertyID")
      expect(property_id).to eq(params[:property_id])
    end

    it 'adds date range to request' do
      xml = builder.build_seasons_fetch_payload(
        params[:property_id],
        params[:date_from],
        params[:date_to]
      )
      hash = to_hash(xml)

      date_from = hash.get("#{root_tag}.DateFrom")
      date_to   = hash.get("#{root_tag}.DateTo")
      expect(date_from.to_s).to eq(params[:date_from])
      expect(date_to.to_s).to eq(params[:date_to])
    end
  end

  describe '#build_price_fetch_payload' do
    let(:stay_params) do
      {
        property_id: "123",
        check_in: "2016-09-01",
        check_out: "2016-09-02",
        num_guests: 3
      }
    end

    it 'embedds username and password to request' do
      xml = builder.build_price_fetch_payload(stay_params)
      hash = to_hash(xml)

      authentication = hash.get("Pull_GetPropertyAvbPrice_RQ.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end

    it 'adds property_id to request' do
      xml = builder.build_price_fetch_payload(stay_params)
      hash = to_hash(xml)

      property_id = hash.get("Pull_GetPropertyAvbPrice_RQ.PropertyID")
      expect(property_id).to eq(stay_params[:property_id])
    end

    it 'adds check in / check out dates to request' do
      xml = builder.build_price_fetch_payload(stay_params)
      hash = to_hash(xml)

      check_in = hash.get("Pull_GetPropertyAvbPrice_RQ.DateFrom").to_s
      check_out = hash.get("Pull_GetPropertyAvbPrice_RQ.DateTo").to_s
      expect(check_in).to eq(stay_params[:check_in])
      expect(check_out).to eq(stay_params[:check_out])
    end

    it 'adds num_guests to request' do
      xml = builder.build_price_fetch_payload(stay_params)
      hash = to_hash(xml)

      num_guests = hash.get("Pull_GetPropertyAvbPrice_RQ.NOP")
      expect(num_guests).to eq(stay_params[:num_guests].to_s)
    end
  end

  private
  def to_hash(xml)
    Concierge::SafeAccessHash.new(Nori.new.parse(xml))
  end
end
