require "spec_helper"

RSpec.describe Workers::Comparison::Property do
  let(:original) {
    Roomorama::Property.new("property1").tap do |property|
      property.title       = "Large House in Singapore"
      property.description = "With open garden space"
      property.max_guests  = 10
      property.amenities   = "parking,wifi"

      image = Roomorama::Image.new("img1")
      image.url     = "https://www.example.org/img1"
      image.caption = "Swimming Pool"
      property.add_image(image)

      image = Roomorama::Image.new("img2")
      image.url = "https://www.example.org/img2"
      property.add_image(image)

      image = Roomorama::Image.new("img3")
      image.url = "https://www.example.org/img3"
      property.add_image(image)
    end
  }

  let(:new) {
    Roomorama::Property.new("property1").tap do |property|
      property.title       = "Large House in Singapore"
      # edited description
      property.description = "With open garden space and a private swimming pool"
      # one more amenity
      property.amenities   = "parking,wifi,internet"

      # no max_guests information

      image = Roomorama::Image.new("img1")
      image.url     = "https://www.example.org/img1"
      image.caption = "Swimming Pool"
      property.add_image(image)

      image = Roomorama::Image.new("img2")
      image.url = "https://www.example.org/unit2/img2"
      # added caption
      image.caption = "The Garden"
      property.add_image(image)

      # img3 was deleted

      # img4 added
      image = Roomorama::Image.new("img4")
      image.url = "https://www.example.org/img4"
      property.add_image(image)
    end
  }

  subject { described_class.new(original, new) }

  describe "#initialize" do
    it "does not allow the comparison of different properties" do
      original.identifier = "invalid"

      expect {
        described_class.new(original, new)
      }.to raise_error Workers::Comparison::Property::DifferentIdentifiersError
    end
  end

  describe "#extract_diff" do
    it "generates a diff including changed attributes and images" do
      diff = subject.extract_diff

      expect(diff).to be_a Roomorama::Diff
      expect(diff.identifier).to eq "property1"
      expect(diff.description).to eq "With open garden space and a private swimming pool"
      expect(diff.amenities).to eq "parking,wifi,internet"
      expect(diff.erased).to eq %w(max_guests)

      images = diff.image_changes.created
      expect(images.size).to eq 1

      image = images.first
      expect(image).to be_a Roomorama::Image
      expect(image.identifier).to eq "img4"
      expect(image.url).to eq "https://www.example.org/img4"

      images = diff.image_changes.updated
      expect(images.size).to eq 1

      image = images.first
      expect(image).to be_a Roomorama::Diff::Image
      expect(image.identifier).to eq "img2"
      expect(image.caption).to eq "The Garden"

      images = diff.image_changes.deleted
      expect(images.size).to eq 1

      expect(images).to eq ["img3"]
    end

    it "is able to capture diffs from different amenities formats" do
      new.amenities = ["parking,wifi,internet"]
      diff = subject.extract_diff

      expect(diff.to_h[:amenities]).to eq "parking,wifi,internet"
    end

    it "is able to recognise that amenities are equal in different formats" do
      new.amenities = ["parking,wifi"]
      diff = subject.extract_diff

      expect(diff.to_h).not_to have_key :amenities
    end

    context "multi units" do
      let(:unit_one) {
        Roomorama::Unit.new("unit1").tap do |unit|
          unit.title       = "Unit 1"
          unit.description = "Largest Unit Available"
          unit.floor       = 4

          image = Roomorama::Image.new("unit1img1")
          image.url     = "https://www.example.org/unit1/img1"
          image.caption = "Swimming Pool"
          unit.add_image(image)

          image = Roomorama::Image.new("unit1img2")
          image.url = "https://www.example.org/unit1/img2"
          unit.add_image(image)
        end
      }

      let(:unit_two) {
        Roomorama::Unit.new("unit2").tap do |unit|
          unit.title       = "Unit 2"
          unit.description = "Sea View"
          unit.floor       = 4

          image = Roomorama::Image.new("unit2img1")
          image.url     = "https://www.example.org/unit2/img1"
          image.caption = "Barbecue Pit"
          unit.add_image(image)

          image = Roomorama::Image.new("unit2img2")
          image.url = "https://www.example.org/unit2/img2"
          unit.add_image(image)
        end
      }

      let(:unit_three) {
        Roomorama::Unit.new("unit3").tap do |unit|
          unit.title = "Unit 3"

          unit.title       = "Unit 3"
          unit.description = "Large Apartment"

          image = Roomorama::Image.new("unit3img1")
          image.url     = "https://www.example.org/unit3/img1"
          image.caption = "Living Room"
          unit.add_image(image)

          image = Roomorama::Image.new("unit3img2")
          image.url = "https://www.example.org/unit3/img2"
          unit.add_image(image)
        end
      }

      let(:unit_four) {
        Roomorama::Unit.new("unit4").tap do |unit|
          unit.title = "Unit 4"

          unit.title       = "Unit 4"
          unit.description = "Japanese Style Ryokan"

          image = Roomorama::Image.new("unit4img1")
          image.url     = "https://www.example.org/unit4/img1"
          image.caption = "Entrance"
          unit.add_image(image)
        end
      }

      let(:modified_unit_two) {
        Roomorama::Unit.new("unit2").tap do |unit|
          unit.title = "Unit 2"

          unit.title       = "Unit 2"
          unit.description = "Beautiful sea view."

          image = Roomorama::Image.new("unit2img1")
          image.url     = "https://www.example.org/unit2/img1"
          image.caption = "Large Barbecue Pit"
          unit.add_image(image)

          image = Roomorama::Image.new("unit2img3")
          image.url = "https://www.example.org/unit2/img3"
          unit.add_image(image)
        end
      }

      it "generates differences for associated units" do
        original.add_unit(unit_one)
        original.add_unit(unit_two)
        original.add_unit(unit_three)

        new.add_unit(unit_one)
        new.add_unit(unit_four)
        new.add_unit(modified_unit_two)

        diff = subject.extract_diff
        expect(diff).to be_a Roomorama::Diff
        expect(diff.identifier).to eq "property1"

        units = diff.unit_changes.created
        expect(units.size).to eq 1

        unit = units.first
        expect(unit).to be_a Roomorama::Unit
        expect(unit.identifier).to eq "unit4"
        expect(unit.images.size).to eq 1

        units = diff.unit_changes.updated
        expect(units.size).to eq 1

        unit = units.first
        expect(unit).to be_a Roomorama::Diff::Unit
        expect(unit.identifier).to eq "unit2"
        expect(unit.title).to be_nil
        expect(unit.description).to eq "Beautiful sea view."

        expect(unit.image_changes.created.size).to eq 1
        expect(unit.image_changes.updated.size).to eq 1
        expect(unit.image_changes.deleted.size).to eq 1

        expect(diff.unit_changes.deleted).to eq ["unit3"]
      end
    end
  end
end
