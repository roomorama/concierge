require 'spec_helper'

module SAW
  RSpec.describe Mappers::RoomoramaUnitSet do
    let(:units_info) do
      [
        {"property_accommodation_name"=>"1 Bedroom", "@id"=>"8368"},
        {"property_accommodation_name"=>"2-Bedroom apartment", "@id"=>"10614"},
        {"property_accommodation_name"=>"Classic Room", "@id"=>"10612"},
        {"property_accommodation_name"=>"Studio", "@id"=>"8367"},
        {"property_accommodation_name"=>"Studio", "@id"=>"10613"}
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
        nightly_rate: 10.35,
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
        address: 'Address',
        country: 'Thailand',
        amenities: ['wifi', 'breakfast'],
        not_supported_amenities: ['foo', 'bar'],
        bedding_configurations: nil,
        property_accommodations: {
          "accommodation_type"=> {
            "@id"=>"95",
            "accommodation_name"=>"1-Bedroom",
            "property_accommodation"=> units_info
          }
        }
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

    let(:images_attributes) do
      [
        { id: '1', url: 'www.example.com/1', caption: 'foo' },
        { id: '2', url: 'www.example.com/2', caption: 'bar' }
      ]
    end

    let(:unit_rates) { nil }

    let(:images) do
      images_attributes.map { |image_hash| Roomorama::Image.new(image_hash) }
    end

    it "builds units" do
      units = described_class.build(
        basic_property,
        detailed_property,
        unit_rates
      )
      expect(units.size).to eq(5)

      units_info.each do |unit_info|
        created_unit = units.detect { |u| u.identifier == unit_info["@id"] }

        expect(created_unit).to be_kind_of(Roomorama::Unit)
        expect(created_unit.identifier).to eq(unit_info["@id"])
        expect(created_unit.title).to eq(unit_info["property_accommodation_name"])
      end
    end

    it "does not copies images to unit from detailed_property" do
      detailed_property.images = images

      units = described_class.build(
        basic_property,
        detailed_property,
        unit_rates
      )
      expect(units.size).to eq(5)

      units_info.each do |unit_info|
        created_unit = units.detect { |u| u.identifier == unit_info["@id"] }

        expect(created_unit).to be_kind_of(Roomorama::Unit)
        expect(created_unit.images).to eq([])
      end
    end

    it "adds amenities information to units" do
      units = described_class.build(
        basic_property,
        detailed_property,
        unit_rates
      )

      units_info.each do |unit_info|
        created_unit = units.detect { |u| u.identifier == unit_info["@id"] }

        expect(created_unit.amenities).to eq(detailed_property.amenities)
      end
    end

    it "adds price information from property to units" do
      units = described_class.build(
        basic_property,
        detailed_property,
        unit_rates
      )

      units_info.each do |unit_info|
        created_unit = units.detect { |u| u.identifier == unit_info["@id"] }

        expect(created_unit.nightly_rate).to eq(basic_property.nightly_rate)
        expect(created_unit.weekly_rate).to eq(basic_property.weekly_rate)
        expect(created_unit.monthly_rate).to eq(basic_property.monthly_rate)
      end
    end

    it "adds description from property to units" do
      units = described_class.build(
        basic_property,
        detailed_property,
        unit_rates
      )

      units_info.each do |unit_info|
        created_unit = units.detect { |u| u.identifier == unit_info["@id"] }

        expect(created_unit.description).to eq(basic_property.description)
      end
    end

    it "adds number of units information" do
      units = described_class.build(
        basic_property,
        detailed_property,
        unit_rates
      )

      units_info.each do |unit_info|
        created_unit = units.detect { |u| u.identifier == unit_info["@id"] }
        expect(created_unit.number_of_units).to eq(1)
      end
    end

    context "when there are multiple accomodation types with units" do
      let(:units_hash) do
        {
          "beddingconfigurations"=>nil,
          "property_accommodations" => {
            "accommodation_type"=> [
              {
                "@id"=>"106",
                "accommodation_name"=>"Studio",
                "property_accommodation"=> {
                  "property_accommodation_name"=>"Himawari Suite",
                  "@id"=>"9512"
                }
              },
              {
                "@id"=>"95",
                "accommodation_name"=>"1-Bedroom",
                "property_accommodation"=> {
                  "property_accommodation_name"=>"1 Bedroom Executive",
                  "@id"=>"9513"
                }
              },
              {
                "@id"=>"198",
                "accommodation_name"=>"2 Bedroom",
                "property_accommodation"=> [
                  {
                    "property_accommodation_name"=>"2 Bedroom Executive",
                    "@id"=>"9514"
                  },
                  {
                    "property_accommodation_name"=>"2 Bedroom Premium",
                    "@id"=>"10354"
                  }
                ]
              },
              {
                "@id"=>"374",
                "accommodation_name"=>"3 Bedroom",
                "property_accommodation"=> {
                  "property_accommodation_name"=>"3 Bedroom Premium",
                  "@id"=>"9516"
                }
              }
            ]
          }
        }
      end

      let(:detailed_property_with_accommodations) do
        SAW::Entities::DetailedProperty.new(
          Concierge::SafeAccessHash.new(
            detailed_property_attributes.merge(
              bedding_configurations: nil,
              property_accommodations: units_hash.fetch("property_accommodations")
            )
          )
        )
      end

      it "builds units" do
        units = described_class.build(
          basic_property,
          detailed_property_with_accommodations,
          unit_rates
        )
        expect(units.size).to eq(5)
      end
    end

    context "when there is only one unit in current accomodation" do
      let(:units_info) do
        {"property_accommodation_name"=>"1 Bedroom", "@id"=>"8368"}
      end

      it "builds units" do
        units = described_class.build(
          basic_property,
          detailed_property,
          unit_rates
        )
        expect(units.size).to eq(1)
      end
    end

    context "with available bedding configuration" do
      let(:unit_beds_configuration) do
        {
          "@id"=>"8367",
          "property_accommodation_name"=>"Studio",
          "bed_types"=> {
            "bed_type"=>[
              {
                "bed_type_name"=>"Double Bed",
                "@id"=>"13102"
              },
              {
                "bed_type_name"=>"Double & Double",
                "@id"=>"13103"
              }
            ]
          }
        }
      end

      RSpec.shared_examples "units mapper" do
        it "builds units" do
          units = described_class.build(
            basic_property,
            detailed_property_with_beds,
            unit_rates
          )
          expect(units.size).to eq(5)

          unit_with_beds = units.detect { |u| u.identifier == "8367" }
          expect(unit_with_beds.number_of_double_beds).to eq(3)
          expect(unit_with_beds.number_of_single_beds).to eq(0)
          expect(unit_with_beds.max_guests).to eq(6)
        end

        it "parses number_of_bedrooms for Studio" do
          units = described_class.build(
            basic_property,
            detailed_property_with_beds,
            unit_rates
          )
          unit_with_beds = units.detect { |u| u.identifier == "8367" }
          expect(unit_with_beds.number_of_bedrooms).to eq(1)
        end

        it "parses number_of_bedrooms for 1-Bedroom" do
          units = described_class.build(
            basic_property,
            detailed_property_with_beds,
            unit_rates
          )
          unit_with_beds = units.detect { |u| u.identifier == "8368" }
          expect(unit_with_beds.number_of_bedrooms).to eq(1)
        end

        it "parses number_of_bedrooms for 2-Bedroom" do
          units = described_class.build(
            basic_property,
            detailed_property_with_beds,
            unit_rates
          )
          unit_with_beds = units.detect { |u| u.identifier == "10614" }
          expect(unit_with_beds.number_of_bedrooms).to eq(2)
        end

        it "parses number_of_bedrooms for unknown names" do
          units = described_class.build(
            basic_property,
            detailed_property_with_beds,
            unit_rates
          )
          unit_with_beds = units.detect { |u| u.identifier == "10612" }
          expect(unit_with_beds.number_of_bedrooms).to eq(1)
        end
      end

      context "when beds configuration is an array" do
        let(:detailed_property_with_beds) do
          attributes = detailed_property_attributes.merge(
            bed_configurations: {
              "property_accommodation" => [unit_beds_configuration]
            }
          )

          safe_hash = Concierge::SafeAccessHash.new(attributes)
          SAW::Entities::DetailedProperty.new(safe_hash)
        end

        it_behaves_like "units mapper"
      end

      context "when beds configuration is a single object" do
        let(:detailed_property_with_beds) do
          attributes = detailed_property_attributes.merge(
            bed_configurations: {
              "property_accommodation" => unit_beds_configuration
            }
          )

          safe_hash = Concierge::SafeAccessHash.new(attributes)
          SAW::Entities::DetailedProperty.new(safe_hash)
        end

        it_behaves_like "units mapper"
      end
    end

    context "when custom property rates are given" do
      let(:unit_rates) do
        SAW::Entities::PropertyRate.new(
          id: '123',
          currency: 'USD',
          units: [
            SAW::Entities::UnitRate.new(id: '8368', price: 200.04, available: true, max_guests: 7),
            SAW::Entities::UnitRate.new(id: '10614', price: 201.04, available: true, max_guests: 8),
            SAW::Entities::UnitRate.new(id: '10612', price: 202.04, available: true, max_guests: 5),
            SAW::Entities::UnitRate.new(id: '8367', price: 203.04, available: true, max_guests: 5),
          ]
        )
      end

      it "copies rates from units, not from property" do
        units = described_class.build(
          basic_property,
          detailed_property,
          unit_rates
        )
        expect(units.size).to eq(5)

        created_unit = units.detect { |u| u.identifier == '8368' }
        expect(created_unit.nightly_rate).to eq(200.04)
        expect(created_unit.weekly_rate).to eq(1400.28)
        expect(created_unit.monthly_rate).to eq(6001.2)

        created_unit = units.detect { |u| u.identifier == '10614' }
        expect(created_unit.nightly_rate).to eq(201.04)
        expect(created_unit.weekly_rate).to eq(1407.28)
        expect(created_unit.monthly_rate).to eq(6031.2)

        created_unit = units.detect { |u| u.identifier == '10612' }
        expect(created_unit.nightly_rate).to eq(202.04)
        expect(created_unit.weekly_rate).to eq(1414.28)
        expect(created_unit.monthly_rate).to eq(6061.2)

        created_unit = units.detect { |u| u.identifier == '8367' }
        expect(created_unit.nightly_rate).to eq(203.04)
        expect(created_unit.weekly_rate).to eq(1421.28)
        expect(created_unit.monthly_rate).to eq(6091.2)
      end

      it "sets rates from property if one of the units has no rates" do
        units = described_class.build(
          basic_property,
          detailed_property,
          unit_rates
        )
        expect(units.size).to eq(5)

        created_unit = units.detect { |u| u.identifier == '10613' }
        expect(created_unit.nightly_rate).to eq(10.35)
        expect(created_unit.weekly_rate).to eq(70.11)
        expect(created_unit.monthly_rate).to eq(300)
      end

      it "sets max_guests from units rate data" do
        units = described_class.build(
          basic_property,
          detailed_property,
          unit_rates
        )
        expect(units.size).to eq(5)

        created_unit = units.detect { |u| u.identifier == '8368' }
        expect(created_unit.max_guests).to eq(7)

        created_unit = units.detect { |u| u.identifier == '10614' }
        expect(created_unit.max_guests).to eq(8)

        created_unit = units.detect { |u| u.identifier == '10612' }
        expect(created_unit.max_guests).to eq(5)

        created_unit = units.detect { |u| u.identifier == '8367' }
        expect(created_unit.max_guests).to eq(5)
      end

      it "sets max_guests from bed_configurations if one of the units has no rates" do
        units = described_class.build(
          basic_property,
          detailed_property,
          unit_rates
        )
        expect(units.size).to eq(5)

        created_unit = units.detect { |u| u.identifier == '10613' }
        expect(created_unit.max_guests).to be_nil
      end
    end
  end
end
