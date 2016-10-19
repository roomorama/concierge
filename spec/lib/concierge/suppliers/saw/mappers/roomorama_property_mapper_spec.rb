require "spec_helper"

RSpec.describe SAW::Mappers::RoomoramaProperty do
  let(:property_images) do
    [
      Roomorama::Image.new("some-id")
    ]
  end

  let(:basic_property_attributes) do
    {
      internal_id: 1234,
      type: 'apartment',
      title: 'Title Basic',
      lon: '10',
      lat: '20',
      currency_code: 'RUB',
      country_code: 'RUS',
      nightly_rate: 10.34,
      weekly_rate: 70.11,
      monthly_rate: 300,
      description: 'Description Basic',
      city: 'City Basic',
      neighborhood: 'Neighborhood Basic',
      multi_unit: true
    }
  end

  let(:detailed_property_attributes) do
    {
      internal_id: 9876,
      type: 'house',
      title: 'Title Detailed',
      lon: '90',
      lat: '80',
      description: 'Description Detailed',
      city: 'City Detailed',
      neighborhood: 'Neighborhood Detailed',
      postal_code: '12345',
      address: 'Address',
      country: 'Thailand',
      amenities: ['wifi', 'breakfast'],
      images: property_images,
      owner_email: 'foo@bar.com',
      owner_phone_number: '123123123',
      not_supported_amenities: []
    }
  end

  let(:basic_property) do
    SAW::Entities::BasicProperty.new(
      Concierge::SafeAccessHash.new(basic_property_attributes)
    )
  end

  let(:detailed_property) do
    SAW::Entities::DetailedProperty.new(
      Concierge::SafeAccessHash.new(detailed_property_attributes)
    )
  end

  let(:rates) { nil }

  it "returns roomorama property entity" do
    property = described_class.build(basic_property, detailed_property, rates)
    expect(property).to be_a(Roomorama::Property)
  end

  it "adds multi-unit flag" do
    property = described_class.build(basic_property, detailed_property, rates)
    expect(property.multi_unit?).to eq(basic_property.multi_unit?)
  end

  it "adds instant_booking flag" do
    property = described_class.build(basic_property, detailed_property, rates)
    expect(property.instant_booking?).to eq(true)
  end

  it "adds default_to_available flag" do
    property = described_class.build(basic_property, detailed_property, rates)
    expect(property.default_to_available).to eq(true)
  end

  it "adds minimum_stay" do
    property = described_class.build(basic_property, detailed_property, rates)
    expect(property.minimum_stay).to eq(1)
  end

  it "adds cancellation policy" do
    property = described_class.build(basic_property, detailed_property, rates)
    expect(property.cancellation_policy).to eq('moderate')
  end

  it "adds to result property needed attributes from basic property" do
    property = described_class.build(basic_property, detailed_property, rates)

    attributes = %i(
      type
      title
      country_code
      nightly_rate
      weekly_rate
      monthly_rate
    )

    expect(property.identifier).to eq(basic_property.internal_id.to_s)
    expect(property.currency).to eq(basic_property.currency_code)
    expect(property.lat).to eq(basic_property.lat)
    expect(property.lng).to eq(basic_property.lon)

    attributes.each do |attr|
      expect(property.send(attr)).to eq(basic_property.send(attr))
    end
  end

  it "adds to result property needed attributes from detailed property" do
    property = described_class.build(basic_property, detailed_property, rates)

    attributes = %i(
      description
      city
      neighborhood
      postal_code
      address
      owner_email
      owner_phone_number
    )

    attributes.each do |attr|
      expect(property.send(attr)).to eq(detailed_property.send(attr))
    end
  end

  it "always keeps amenities empty" do
    property = described_class.build(basic_property, detailed_property, rates)

    expect(property.amenities).to eq([])
  end

  it "keeps images empty if there was no images given" do
    detailed_property.images = []

    property = described_class.build(basic_property, detailed_property, rates)

    expect(property.images).to eq([])
  end

  it "adds images if there was images provided" do
    property = described_class.build(basic_property, detailed_property, rates)

    expect(property.images).not_to eq([])
    expect(property.images.size).to eq(detailed_property.images.size)
    expect(property.images).to eq(detailed_property.images)
  end

  it "keeps units empty if there was no bed_configurations and accommodations" do
    property = described_class.build(basic_property, detailed_property, rates)

    expect(property.units).to eq([])
  end

  context "when detailed_property has units information" do
    let(:attributes) do
      detailed_property_attributes.merge(
        {
          bed_configurations: {
            "property_accommodation"=>
              [{"property_accommodation_name"=>"1 Bedroom Suite", "bed_types"=>{"bed_type"=>{"bed_type_name"=>"Double Bed", "@id"=>"12934"}}, "@id"=>"10252"},
               {"property_accommodation_name"=>"2 Bedroom Suite", "bed_types"=>{"bed_type"=>{"bed_type_name"=>"Double & Twin", "@id"=>"12935"}}, "@id"=>"10253"},
               {"property_accommodation_name"=>"2 Bedroom Villa", "bed_types"=>{"bed_type"=>{"bed_type_name"=>"Double & Twin", "@id"=>"12936"}}, "@id"=>"10255"},
               {"property_accommodation_name"=>"3 Bedroom Pool Suite",
                "bed_types"=>{"bed_type"=>{"bed_type_name"=>"Double & Double & Twin", "@id"=>"12937"}},
                "@id"=>"10254"},
               {"property_accommodation_name"=>"3 Bedroom Pool Villa",
                "bed_types"=>{"bed_type"=>{"bed_type_name"=>"Double & Double & Twin", "@id"=>"12938"}},
                "@id"=>"10256"},
               {"property_accommodation_name"=>"4 Bedroom Pool Villa",
                "bed_types"=>{"bed_type"=>{"bed_type_name"=>"Double & Double & Double & Twin", "@id"=>"12939"}},
                "@id"=>"10257"}
              ]
          },
          property_accommodations: {
            "accommodation_type"=>
              [{"accommodation_name"=>"1-Bedroom", "property_accommodation"=>{"property_accommodation_name"=>"1 Bedroom Suite", "@id"=>"10252"}, "@id"=>"95"},
               {"accommodation_name"=>"2 Bedroom - 1 Bathroom",
                "property_accommodation"=>
                 [{"property_accommodation_name"=>"2 Bedroom Suite", "@id"=>"10253"}, {"property_accommodation_name"=>"2 Bedroom Villa", "@id"=>"10255"}],
                "@id"=>"96"},
               {"accommodation_name"=>"3 Bedroom - 2 Bathroom",
                "property_accommodation"=>
                 [{"property_accommodation_name"=>"3 Bedroom Pool Suite", "@id"=>"10254"}, {"property_accommodation_name"=>"3 Bedroom Pool Villa", "@id"=>"10256"}],
                "@id"=>"99"},
               {"accommodation_name"=>"4 Bedroom - 3 Bathroom",
                "property_accommodation"=>{"property_accommodation_name"=>"4 Bedroom Pool Villa", "@id"=>"10257"},
                "@id"=>"103"}
              ]
          }
        }
      )
    end

    let(:detailed_property_with_units) do
      SAW::Entities::DetailedProperty.new(
        Concierge::SafeAccessHash.new(attributes)
      )
    end

    it "adds units" do
      property = described_class.build(
        basic_property,
        detailed_property_with_units,
        rates
      )

      expect(property.units.size).to eq(6)
      expect(property.units).to all(be_kind_of(Roomorama::Unit))
    end
  end

  describe "changes description to include additional amenities" do
    it "adds additional amenities to description" do
      detailed_property_attributes[:not_supported_amenities] = ["foo", "bar"]

      property = described_class.build(
        basic_property,
        detailed_property,
        rates
      )

      expect(property.description).to eq(
        "Description Detailed. Additional amenities: foo, bar"
      )
    end

    it "adds only additional amenities to description when description is blank" do
      variations = ["", " ", nil]

      variations.each do |desc|
        detailed_property_attributes[:description] = desc
        detailed_property_attributes[:not_supported_amenities] = ["foo", "bar"]

        property = described_class.build(
          basic_property,
          detailed_property,
          rates
        )

        expect(property.description).to eq("Additional amenities: foo, bar")
      end
    end

    it "doesn't add additional amenities to description when they are empty" do
      detailed_property_attributes[:not_supported_amenities] = []

      property = described_class.build(
        basic_property,
        detailed_property,
        rates
      )

      expect(property.description).to eq("Description Detailed")
    end

    it "keeps description empty when there is no additional amenities and original description" do
      detailed_property_attributes[:description] = nil
      detailed_property_attributes[:not_supported_amenities] = []

      property = described_class.build(
        basic_property,
        detailed_property,
        rates
      )

      expect(property.description).to eq(nil)
    end
  end

  describe "sets cleaning fee attributes" do
    it "keeps cleaning fee attributes empty if there is no free_cleaning amenity" do
      detailed_property_attributes[:amenities] = ["foo", "bar"]

      property = described_class.build(
        basic_property,
        detailed_property,
        rates
      )

      expect(property.services_cleaning).to be_nil
      expect(property.services_cleaning_required).to be_nil
      expect(property.services_cleaning_rate).to be_nil
    end

    it "sets cleaning fee attributes if free_cleaning amenity is present" do
      detailed_property_attributes[:amenities] = ["foo", "bar", "free_cleaning"]

      property = described_class.build(
        basic_property,
        detailed_property,
        rates
      )

      expect(property.services_cleaning).to be true
      expect(property.services_cleaning_required).to be false
      expect(property.services_cleaning_rate).to eq(0)
    end
  end
end
