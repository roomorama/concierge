require "spec_helper"

RSpec.describe SAW::PayloadBuilder do
  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:payload_builder) { described_class.new(credentials) }

  describe '#build_compute_pricing' do
    let(:payload) do
      {
        property_id: 1,
        unit_id: "-1",
        check_in: '02/06/2016',
        check_out: '03/06/2016',
        num_guests: 1
      }
    end

    it 'raises an exception without params which are required by SAW api' do
      required_keys = %i(
        property_id unit_id check_in check_out num_guests
      )

      required_keys.each do |key|
        wrong_payload = payload.dup.delete(key)

        expect {
          payload_builder.build_compute_pricing(wrong_payload)
        }.to raise_error(ArgumentError)
      end
    end

    it 'embedds username and password to request' do
      response = to_hash(payload_builder.build_compute_pricing(payload))

      response_attrs = response.fetch("request")
      username = response_attrs.fetch("username")
      password = response_attrs.fetch("password")

      expect(username).to eq(username)
      expect(password).to eq(password)
    end

    it 'sets property request parameters' do
      response = to_hash(payload_builder.build_compute_pricing(payload))

      response_attrs = response.fetch("request")

      property_id   = response_attrs.fetch("propertyid")
      check_in      = response_attrs.fetch("check_in")
      check_out     = response_attrs.fetch("check_out")

      expect(property_id).to eq(payload[:property_id].to_s)
      expect(check_in).to eq(payload[:check_in])
      expect(check_out).to eq(payload[:check_out])
    end

    it 'sets apartment type parameters' do
      response = to_hash(payload_builder.build_compute_pricing(payload))

      response_attrs = response.fetch("request")
      accommodation_type = response_attrs.fetch("apartments")
                                         .fetch("accommodation_type")

      number_of_guests = accommodation_type.fetch("number_of_guests")
      expect(number_of_guests).to eq(payload[:num_guests].to_s)
    end

    it "sets unit type id" do
      response = to_hash(payload_builder.build_compute_pricing(payload))

      response_attrs = response.fetch("request")
      accommodation_type = response_attrs.fetch("apartments")
                                         .fetch("accommodation_type")

      id = accommodation_type.fetch("accommodation_typeid")
      expect(id).to eq(payload_builder.class::ALL_ACCOMODATIONS_TYPE_CODE.to_s)
    end

    it "sets unit type to ALL when it's not provided" do
      payload[:unit_id] = nil
      response = to_hash(payload_builder.build_compute_pricing(payload))

      response_attrs = response.fetch("request")
      accommodation_type = response_attrs.fetch("apartments")
                                         .fetch("accommodation_type")

      id = accommodation_type.fetch("accommodation_typeid")
      expect(id).to eq(payload_builder.class::ALL_ACCOMODATIONS_TYPE_CODE.to_s)
    end

    it 'embedds flag_rateplan tag (used to fetch only best available rates)' do
      response = to_hash(payload_builder.build_compute_pricing(payload))

      response_attrs = response.fetch("request")
      expect(response_attrs.fetch("flag_rateplan")).to eq("N")
    end
  end

  describe '#build_booking_request' do
    let(:payload) do
      {
        property_id: 1850,
        unit_id: 9733,
        currency_code: 'EUR',
        check_in: '02/06/2016',
        check_out: '03/06/2016',
        total: '123.45',
        num_guests: 1,
        user: {
          first_name: 'Test',
          last_name: 'User',
          email: 'testuser@example.com'
        }
      }
    end

    it 'embedds username and password to request' do
      response = to_hash(payload_builder.build_booking_request(payload))

      response_attrs = response.fetch("request")
      username = response_attrs.fetch("username")
      password = response_attrs.fetch("password")

      expect(username).to eq(username)
      expect(password).to eq(password)
    end

    it 'embedds property id and unit id to request' do
      response = to_hash(payload_builder.build_booking_request(payload))

      response_attrs = response.fetch("request")
      property_id = response_attrs.fetch("propertyid")
      unit_id = response_attrs.fetch("apartments")
                              .fetch("property_accommodation")
                              .fetch("property_accommodationid")

      expect(property_id).to eq(payload.fetch(:property_id).to_s)
      expect(unit_id).to eq(payload.fetch(:unit_id).to_s)
    end

    it 'embedds booking details' do
      response = to_hash(payload_builder.build_booking_request(payload))

      response_attrs = response.fetch("request")
      check_in = response_attrs.fetch("check_in")
      check_out = response_attrs.fetch("check_out")
      currency_code = response_attrs.fetch("currency_code")

      expect(check_in).to eq(payload.fetch(:check_in))
      expect(check_out).to eq(payload.fetch(:check_out))
      expect(currency_code).to eq(payload.fetch(:currency_code))
    end

    it "embedds customer details" do
      response = to_hash(payload_builder.build_booking_request(payload))

      response_attrs = response.fetch("request")
      customer_attrs = response_attrs.fetch("customer_detail")
      first_name = customer_attrs.fetch("first_name")
      last_name = customer_attrs.fetch("last_name")
      email = customer_attrs.fetch("email")

      expect(first_name).to eq(payload.fetch(:user).fetch(:first_name))
      expect(last_name).to eq(payload.fetch(:user).fetch(:last_name))
      expect(email).to eq(payload.fetch(:user).fetch(:email))
    end

    it "embedds guest details" do
      response = to_hash(payload_builder.build_booking_request(payload))

      response_attrs = response.fetch("request")
      guest_attrs = response_attrs.fetch("apartments")
                                  .fetch("property_accommodation")

      num_guests = guest_attrs.fetch("number_of_guests")
      first_name = guest_attrs.fetch("guest_first_name")
      last_name = guest_attrs.fetch("guest_last_name")

      expect(num_guests).to eq(payload.fetch(:num_guests).to_s)
      expect(first_name).to eq(payload.fetch(:user).fetch(:first_name))
      expect(last_name).to eq(payload.fetch(:user).fetch(:last_name))
    end
  end

  describe '#build_countries_request' do
    it 'embedds username and password to request' do
      response = to_hash(payload_builder.build_countries_request)

      response_attrs = response.fetch("request")
      username = response_attrs.fetch("username")
      password = response_attrs.fetch("password")

      expect(username).to eq(username)
      expect(password).to eq(password)
    end
  end

  describe '#propertysearch_request' do
    let(:payload) do
      {
        country: "1850",
        property_id: "2323"
      }
    end

    it 'embedds username and password to request' do
      response = to_hash(payload_builder.propertysearch_request(payload))

      response_attrs = response.fetch("request")
      username = response_attrs.fetch("username")
      password = response_attrs.fetch("password")

      expect(username).to eq(username)
      expect(password).to eq(password)
    end

    it "embedds country details" do
      response = to_hash(payload_builder.propertysearch_request(payload))

      response_attrs = response.fetch("request")
      country_id = response_attrs.fetch("countryid")

      expect(country_id).to eq(payload.fetch(:country))
    end

    it "embedds property details" do
      response = to_hash(payload_builder.propertysearch_request(payload))

      response_attrs = response.fetch("request")
      properties = response_attrs.fetch("properties")

      expect(properties).to eq({ "propertyid" => "2323" })
    end

    it "does not embedds property details if property_id is not provided" do
      payload[:property_id] = nil

      response = to_hash(payload_builder.propertysearch_request(payload))

      response_attrs = response.fetch("request")

      expect {
        response_attrs.fetch("properties")
      }.to raise_error(KeyError)
    end
  end

  describe '#propertydetail_request' do
    let(:property_id) { "1222" }

    it 'embedds username and password to request' do
      response = to_hash(payload_builder.propertydetail_request(property_id))

      response_attrs = response.fetch("request")
      username = response_attrs.fetch("username")
      password = response_attrs.fetch("password")

      expect(username).to eq(username)
      expect(password).to eq(password)
    end

    it 'embedds property_id to the payload' do
      response = to_hash(payload_builder.propertydetail_request(property_id))

      response_attrs = response.fetch("request")
      expect(response_attrs.fetch("propertyid")).to eq(property_id)
    end
  end

  describe '#build_cancel_request' do
    let(:reservation_id) { "MT010203" }

    it 'embedds username and password to request' do
      response = to_hash(payload_builder.build_cancel_request(reservation_id))

      response_attrs = response.fetch("request")
      username = response_attrs.fetch("username")
      password = response_attrs.fetch("password")

      expect(username).to eq(username)
      expect(password).to eq(password)
    end

    it 'embedds reservation_id to request' do
      response = to_hash(payload_builder.build_cancel_request(reservation_id))

      response_attrs = response.fetch("request")
      expect(response_attrs.fetch("booking_ref_number")).to eq(reservation_id)
    end
  end

  describe '#build_property_rate_request' do
    let(:params) do
      {
        ids: "1, 2, 3, 4",
        check_in: "01/06/2016",
        check_out: "02/06/2016",
        guests: 99
      }
    end

    it 'embedds username and password to request' do
      response = to_hash(payload_builder.build_property_rate_request(params))

      response_attrs = response.fetch("request")
      username = response_attrs.fetch("username")
      password = response_attrs.fetch("password")

      expect(username).to eq(username)
      expect(password).to eq(password)
    end

    it 'embedds given ids to request' do
      response = to_hash(payload_builder.build_property_rate_request(params))

      response_attrs = response.fetch("request")
      expect(response_attrs.fetch("propertyid")).to eq(params[:ids])
    end

    it 'embedds check_in and check_out to request' do
      response = to_hash(payload_builder.build_property_rate_request(params))

      response_attrs = response.fetch("request")
      expect(response_attrs.fetch("check_in")).to eq(params[:check_in])
      expect(response_attrs.fetch("check_out")).to eq(params[:check_out])
    end

    it 'embedds flag_rateplan tag (used to fetch only best available rates)' do
      response = to_hash(payload_builder.build_property_rate_request(params))

      response_attrs = response.fetch("request")
      expect(response_attrs.fetch("flag_rateplan")).to eq("N")
    end
  end

  private
  def to_hash(response)
    Nori.new.parse(response)
  end
end
