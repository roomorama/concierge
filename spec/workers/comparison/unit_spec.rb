require "spec_helper"

RSpec.describe Workers::Comparison::Unit do
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

  let(:original_units) { [unit_one, unit_two, unit_three] }
  let(:new_units)      { [modified_unit_two, unit_one, unit_four] }

  subject { described_class.new(original_units, new_units) }

  it "generates a unit diff, including units to be added, changed and deleted" do
    diff = subject.extract_diff

    expect(diff).to have_key :create
    expect(diff).to have_key :update
    expect(diff).to have_key :delete

    created = diff[:create]
    expect(created.size).to eq 1

    unit = created.first
    expect(unit).to be_a Roomorama::Unit
    expect(unit.identifier).to eq "unit4"
    expect(unit.title).to eq "Unit 4"

    images = unit.images
    expect(images.size).to eq 1

    image = images.first
    expect(image).to be_a Roomorama::Image
    expect(image.identifier).to eq "unit4img1"
    expect(image.url).to eq "https://www.example.org/unit4/img1"
    expect(image.caption).to eq "Entrance"

    updated = diff[:update]
    expect(updated.size).to eq 1

    unit_diff = updated.first
    expect(unit_diff).to be_a Roomorama::Diff::Unit
    expect(unit_diff.description).to eq "Beautiful sea view."
    expect(unit_diff.erased).to eq %w(floor)

    new_images = unit_diff.image_changes.created
    expect(new_images.size).to eq 1

    image = new_images.first
    expect(image).to be_a Roomorama::Image
    expect(image.identifier).to eq "unit2img3"
    expect(image.url).to eq "https://www.example.org/unit2/img3"

    updated_images = unit_diff.image_changes.updated
    expect(updated_images.size).to eq 1

    image_diff = updated_images.first
    expect(image_diff).to be_a Roomorama::Diff::Image
    expect(image_diff.identifier).to eq "unit2img1"
    expect(image_diff.caption).to eq "Large Barbecue Pit"

    expect(unit_diff.image_changes.deleted).to eq ["unit2img2"]

    deleted = diff[:delete]
    expect(deleted.size).to eq 1

    expect(deleted).to eq ["unit3"]
  end

  it "does not include one field if there are no elements in it" do
    original_units = [unit_one, unit_two, unit_three]
    new_units      = [unit_two, unit_one, unit_four]

    subject = described_class.new(original_units, new_units)
    diff    = subject.extract_diff

    expect(diff).to     have_key :create
    expect(diff).not_to have_key :update
    expect(diff).to     have_key :delete

    expect(diff[:create].first.identifier).to eq "unit4"
    expect(diff[:delete]).to eq ["unit3"]
  end

  it "is empty when there are no changes at all" do
    original_units = [unit_one, unit_two, unit_three]
    new_units      = [unit_two, unit_three, unit_one]

    subject = described_class.new(original_units, new_units)
    diff    = subject.extract_diff

    expect(diff).to eq({})
  end
end
