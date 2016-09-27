require "spec_helper"

RSpec.describe RentalsUnited::Mappers::RoomoramaProperty do
  include Support::Fixtures

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
      floor:                   5,
      description:             "Test Description",
      images:                  [],
      amenities:               []
    }
  end

  let(:ru_property) { RentalsUnited::Entities::Property.new(ru_property_hash) }

  let(:location) do
    double(
      id: '1505',
      city: 'Paris',
      neighborhood: 'Ile-de-France',
      country: 'France',
      currency: 'EUR'
    )
  end

  let(:owner) do
    double(
      id: '478000',
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@gmail.com',
      phone: '3128329138'
    )
  end

  let(:subject) { described_class.new(ru_property, location, owner) }
  let(:result) { subject.build_roomorama_property }
  let(:property) { result.value }

  it "builds property object" do
    expect(property).to be_kind_of(Roomorama::Property)
  end

  it "sets id to the property" do
    expect(property.identifier).to eq(ru_property.id)
  end

  it "sets title to the property" do
    expect(property.title).to eq(ru_property.title)
  end

  it "sets description to the property" do
    expect(property.description).to eq(ru_property.description)
  end

  it "sets type to the property" do
    expect(property.type).to eq("house")
  end

  it "sets subtype to the property" do
    expect(property.subtype).to eq("villa")
  end

  it "sets max_guests to the property" do
    expect(property.max_guests).to eq(ru_property.max_guests)
  end

  it "sets number_of_bedrooms to the property" do
    expect(property.number_of_bedrooms).to eq(3)
  end

  it "sets floor to the property" do
    expect(property.floor).to eq(5)
  end

  it "sets surface to the property" do
    expect(property.surface).to eq(ru_property.surface)
  end

  it "sets surface_unit to the property" do
    expect(property.surface_unit).to eq("metric")
  end

  it "sets address information to the property" do
    expect(property.lat).to eq(55.0003426)
    expect(property.lng).to eq(73.2965942999999)
    expect(property.address).to eq("Test street address")
    expect(property.city).to eq("Paris")
    expect(property.neighborhood).to eq("Ile-de-France")
    expect(property.postal_code).to eq("644119")
    expect(property.country_code).to eq("FR")
  end

  it "sets check_in_time to the property" do
    expect(property.check_in_time).to eq("13:00-17:00")
  end

  it "sets check_out_time to the property" do
    expect(property.check_out_time).to eq("11:00")
  end

  it "sets currency to the property" do
    expect(property.currency).to eq("EUR")
  end

  it "sets cancellation_policy to the property" do
    expect(property.cancellation_policy).to eq("super_elite")
  end

  it "sets default_to_available flag to false" do
    expect(property.default_to_available).to eq(false)
  end

  it "does not set multi-unit flag" do
    expect(property.multi_unit).to be_nil
  end

  it "sets instant_booking flag" do
    expect(property.instant_booking?).to eq(true)
  end

  it "sets owner name" do
    expect(property.owner_name).to eq("John Doe")
  end

  it "sets owner email" do
    expect(property.owner_email).to eq("john.doe@gmail.com")
  end

  it "sets owner phone number" do
    expect(property.owner_phone_number).to eq("3128329138")
  end

  it "sets security_deposit_amount" do
    expect(property.security_deposit_amount).to eq(5.5)
  end

  it "sets security_deposit_currency_code" do
    expect(property.security_deposit_currency_code).to eq("EUR")
  end

  it "sets security_deposit_currency_code" do
    expect(property.security_deposit_type).to eq("unknown")
  end

  context "when property has no security_deposit" do
    it "sets security_deposit_amount to nil" do
      ru_property_hash[:security_deposit_type] = "1"
      expect(property.security_deposit_amount).to be_nil
    end

    it "sets security_deposit_currency_code to nil" do
      ru_property_hash[:security_deposit_type] = "1"
      expect(property.security_deposit_currency_code).to be_nil
    end

    it "sets security_deposit_type to nil" do
      ru_property_hash[:security_deposit_type] = "1"
      expect(property.security_deposit_type).to be_nil
    end
  end

  context "when property has not supported security_deposit" do
    ["2", "3", "4"].each do |type_id|
      it "returns security_deposit_error" do
        ru_property_hash[:security_deposit_type] = type_id
        expect(result).not_to be_success
        expect(result.error.code).to eq(:security_deposit_not_supported)
      end
    end
  end

  context "when property is archived" do
    it "returns error" do
      ru_property_hash[:archived] = true

      expect(result).not_to be_success
      expect(result.error.code).to eq(:attempt_to_build_archived_property)
    end
  end

  context "when property is not active" do
    it "returns error" do
      ru_property_hash[:active] = false

      expect(result).not_to be_success
      expect(result.error.code).to eq(:attempt_to_build_not_active_property)
    end
  end

  context "when property is hotel-typed" do
    it "returns error" do
      ru_property_hash[:property_type_id] = 20

      expect(result).not_to be_success
      expect(result.error.code).to eq(:property_type_not_supported)
    end
  end

  context "when property is boat-typed" do
    it "returns error" do
      ru_property_hash[:property_type_id] = 64

      expect(result).not_to be_success
      expect(result.error.code).to eq(:property_type_not_supported)
    end
  end

  context "when property is camping-typed" do
    it "returns error" do
      ru_property_hash[:property_type_id] = 66

      expect(result).not_to be_success
      expect(result.error.code).to eq(:property_type_not_supported)
    end
  end

  context "when mapping amenities" do
    let(:amenities) do
      ["7", "100", "180", "187", "227", "281", "368", "596", "689", "802", "803"]
    end

    it "adds amenities to property" do
      ru_property_hash[:amenities] = amenities

      expect(property.amenities).to eq(
        ["bed_linen_and_towels", "airconditioning", "pool", "wheelchairaccess", "elevator", "parking"]
      )
    end

    it "sets smoking_allowed to false" do
      amenities_dict = RentalsUnited::Dictionaries::Amenities

      expect_any_instance_of(amenities_dict)
        .to(receive(:smoking_allowed?))
        .and_return(false)


      expect(property.smoking_allowed).to eq(false)
    end

    it "sets smoking_allowed to true" do
      amenities_dict = RentalsUnited::Dictionaries::Amenities

      expect_any_instance_of(amenities_dict)
        .to(receive(:smoking_allowed?))
        .and_return(true)

      expect(property.smoking_allowed).to eq(true)
    end

    it "sets pets_allowed to false" do
      amenities_dict = RentalsUnited::Dictionaries::Amenities

      expect_any_instance_of(amenities_dict)
        .to(receive(:pets_allowed?))
        .and_return(false)

      expect(property.pets_allowed).to eq(false)
    end

    it "sets pets_allowed to true" do
      amenities_dict = RentalsUnited::Dictionaries::Amenities

      expect_any_instance_of(amenities_dict)
        .to(receive(:pets_allowed?))
        .and_return(true)

      expect(property.pets_allowed).to eq(true)
    end
  end

  context "when there is no amenities" do
    let(:amenities) { [] }

    it "keeps amenities empty" do
      expect(property.amenities).to eq([])
    end
  end

  context "when mapping images" do
    let(:image) do
      image = Roomorama::Image.new("1")
      image.url     = "http://url.com/123.jpg"
      image.caption = "house"
      image
    end

    let(:images) do
      [image]
    end

    it "adds images to property" do
      ru_property_hash[:images] = images

      expect(property.images).to eq(images)
    end
  end

  context "when there is no images" do
    it "keeps amenities empty" do
      ru_property_hash[:images] = []

      expect(property.images).to eq([])
    end
  end
end
