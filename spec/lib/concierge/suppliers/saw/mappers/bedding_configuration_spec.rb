require 'spec_helper'

module SAW
  RSpec.describe Mappers::BeddingConfiguration do
    RSpec.shared_examples "builds beds" do
      it "returns BeddingConfiguration entity" do
        entity = described_class.build(config)
        expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
      end

      it "handles single bed correctly" do
        variations = ["Single", "Single Bed", "single", "my single bed"]

        variations.each do |bed_name|
          config_attributes["bed_type"] = [
            "bed_type_name"=>bed_name, "@id"=>"13102"
          ]

          entity = described_class.build(config)
          expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
          expect(entity.number_of_single_beds).to eq(1)
          expect(entity.number_of_double_beds).to eq(0)
        end
      end

      it "handles double bed correctly" do
        variations = ["Double Bed", "Double", "double", "my double bed"]

        variations.each do |bed_name|
          config_attributes["bed_type"] = [
            "bed_type_name"=>bed_name, "@id"=>"13102"
          ]

          entity = described_class.build(config)
          expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
          expect(entity.number_of_single_beds).to eq(0)
          expect(entity.number_of_double_beds).to eq(1)
        end
      end

      it "handles twin bed correctly" do
        variations = ["Twin", "twin"]

        variations.each do |bed_name|
          config_attributes["bed_type"] = [
            "bed_type_name"=>bed_name, "@id"=>"13102"
          ]

          entity = described_class.build(config)
          expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
          expect(entity.number_of_single_beds).to eq(2)
          expect(entity.number_of_double_beds).to eq(0)
        end
      end

      it "handles bunk bed correctly" do
        variations = ["Bunk Bed", "bunk bed", "Bunk", "bunk"]

        variations.each do |bed_name|
          config_attributes["bed_type"] = [
            "bed_type_name"=>bed_name, "@id"=>"13102"
          ]

          entity = described_class.build(config)
          expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
          expect(entity.number_of_single_beds).to eq(2)
          expect(entity.number_of_double_beds).to eq(0)
        end
      end

      it "handles sofa bed correctly" do
        variations = ["Sofa", "sofa", "Sofa Bed", "sofa bed"]

        variations.each do |bed_name|
          config_attributes["bed_type"] = [
            "bed_type_name"=>bed_name, "@id"=>"13102"
          ]

          entity = described_class.build(config)
          expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
          expect(entity.number_of_single_beds).to eq(1)
          expect(entity.number_of_double_beds).to eq(0)
        end
      end

      it "handles combinations of different bed types correctly" do
        config_attributes["bed_type"] = [
          "bed_type_name"=>"Double & Double & Single", "@id"=>"13102"
        ]

        entity = described_class.build(config)
        expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
        expect(entity.number_of_single_beds).to eq(1)
        expect(entity.number_of_double_beds).to eq(2)
      end

      it "handles combinations of different bed types correctly" do
        config_attributes["bed_type"] = [
          "bed_type_name"=>"Double Bed & Twin", "@id"=>"13102"
        ]

        entity = described_class.build(config)
        expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
        expect(entity.number_of_single_beds).to eq(2)
        expect(entity.number_of_double_beds).to eq(1)
      end

      it "handles combinations with bunk type" do
        config_attributes["bed_type"] = [
          "bed_type_name"=>"Double Bed & Bunk Bed", "@id"=>"13102"
        ]

        entity = described_class.build(config)
        expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
        expect(entity.number_of_single_beds).to eq(2)
        expect(entity.number_of_double_beds).to eq(1)
      end

      it "handles combinations with multiple bunk type" do
        config_attributes["bed_type"] = [
          "bed_type_name"=>"Double Bed & Bunk Bed & Bunk", "@id"=>"13102"
        ]

        entity = described_class.build(config)
        expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
        expect(entity.number_of_single_beds).to eq(4)
        expect(entity.number_of_double_beds).to eq(1)
      end

      it "handles combinations with sofa bed type" do
        config_attributes["bed_type"] = [
          "bed_type_name"=>"Double Bed & Sofa Bed", "@id"=>"13102"
        ]

        entity = described_class.build(config)
        expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
        expect(entity.number_of_single_beds).to eq(1)
        expect(entity.number_of_double_beds).to eq(1)
      end

      it "handles combinations with multiple sofa beds" do
        config_attributes["bed_type"] = [
          "bed_type_name"=>"Double Bed & Sofa Bed & Single & Sofa & Sofa", "@id"=>"13102"
        ]

        entity = described_class.build(config)
        expect(entity).to be_kind_of(SAW::Entities::BeddingConfiguration)
        expect(entity.number_of_single_beds).to eq(4)
        expect(entity.number_of_double_beds).to eq(1)
      end
    end

    context "when there is only one bed type" do
      let(:config_attributes) do
        {
          "bed_type"=> {
            "bed_type_name"=>"Double Bed", "@id"=>"13102"
          }
        }
      end

      let(:config) { Concierge::SafeAccessHash.new(config_attributes) }

      it_behaves_like "builds beds"
    end

    context "when there is a bed type inside array" do
      let(:config_attributes) do
        {
          "bed_type"=>[
            {
              "bed_type_name"=>"Double Bed", "@id"=>"13102"
            }
          ]
        }
      end

      let(:config) { Concierge::SafeAccessHash.new(config_attributes) }
      
      it_behaves_like "builds beds"
    end
  end
end
