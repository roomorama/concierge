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

  describe '#build_booking_payload' do
    let(:reservation_params) do
      {
        property_id: "123",
        check_in: "2016-09-01",
        check_out: "2016-09-02",
        num_guests: 3,
        total: "125.40",
        user: {
          first_name: "Test",
          last_name: "User",
          email: "testuser@example.com",
          phone: "111-222-333",
          address: "Address st 45",
          postal_code: "98456"
        }
      }
    end

    let(:root) { "Push_PutConfirmedReservationMulti_RQ" }
    let(:reservation_root) { "#{root}.Reservation" }
    let(:stay_info) { "#{reservation_root}.StayInfos.StayInfo" }

    it 'embedds username and password to request' do
      xml = builder.build_booking_payload(reservation_params)
      hash = to_hash(xml)

      authentication = hash.get("#{root}.Authentication")
      expect(authentication.get("UserName")).to eq(credentials.username)
      expect(authentication.get("Password")).to eq(credentials.password)
    end

    it 'adds property_id to request' do
      xml = builder.build_booking_payload(reservation_params)
      hash = to_hash(xml)

      property_id = hash.get("#{stay_info}.PropertyID")
      expect(property_id).to eq(reservation_params[:property_id])
    end

    it 'adds check in / check out dates to request' do
      xml = builder.build_booking_payload(reservation_params)
      hash = to_hash(xml)

      check_in = hash.get("#{stay_info}.DateFrom").to_s
      check_out = hash.get("#{stay_info}.DateTo").to_s
      expect(check_in).to eq(reservation_params[:check_in])
      expect(check_out).to eq(reservation_params[:check_out])
    end

    it 'adds num_guests to request' do
      xml = builder.build_booking_payload(reservation_params)
      hash = to_hash(xml)

      num_guests = hash.get("#{stay_info}.NumberOfGuests")
      expect(num_guests).to eq(reservation_params[:num_guests].to_s)
    end

    it 'adds total price to request' do
      xml = builder.build_booking_payload(reservation_params)
      hash = to_hash(xml)

      ru_price = hash.get("#{stay_info}.Costs.RUPrice")
      client_price = hash.get("#{stay_info}.Costs.ClientPrice")
      already_paid = hash.get("#{stay_info}.Costs.AlreadyPaid")
      expect(ru_price).to eq(reservation_params[:total])
      expect(client_price).to eq(reservation_params[:total])
      expect(already_paid).to eq(reservation_params[:total])
    end

    it 'adds user information to request' do
      xml = builder.build_booking_payload(reservation_params)
      hash = to_hash(xml)

      first_name = hash.get("#{reservation_root}.CustomerInfo.Name")
      last_name = hash.get("#{reservation_root}.CustomerInfo.SurName")
      email = hash.get("#{reservation_root}.CustomerInfo.Email")
      phone = hash.get("#{reservation_root}.CustomerInfo.Phone")
      address = hash.get("#{reservation_root}.CustomerInfo.Address")
      postal_code = hash.get("#{reservation_root}.CustomerInfo.ZipCode")

      expect(first_name).to eq(reservation_params[:user][:first_name])
      expect(last_name).to eq(reservation_params[:user][:last_name])
      expect(email).to eq(reservation_params[:user][:email])
      expect(phone).to eq(reservation_params[:user][:phone])
      expect(address).to eq(reservation_params[:user][:address])
      expect(postal_code).to eq(reservation_params[:user][:postal_code])
    end
  end

  private
  def to_hash(xml)
    Concierge::SafeAccessHash.new(Nori.new.parse(xml))
  end
end
