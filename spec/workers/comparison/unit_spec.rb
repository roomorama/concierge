require "spec_helper"

RSpec.describe Workers::Comparison::Unit do
  let(:original_unit) {
    Roomorama::Unit.new("unit1").tap do |unit|
      unit.title = "Unit 1"
      unit.description = "Largest Unit Available"
      unit.floor = 4

      image = Roomorama::Image.new("unit1img1")
      image.url = "https://www.example.org/img1"
      image.caption = "Swimming Pool"
      unit.add_image(image)

      image = Roomorama::Image.new("unit1img2")
      image.url = "https://www.example.org/img2"
      unit.add_image(image)
    end
  }

  let(:new_unit) {
    Roomorama::Unit.new("unit1").tap do |unit|
      unit.title = "Unit 1"

      # description is edited
      unit.description = "Largest Unit Available, including a private garden"

      # floor is no longer declared, should be removed

      image = Roomorama::Image.new("unit1img1")
      image.url = "https://www.example.org/img1"
      # caption is edited
      image.caption = "Swimming Pool, heated water"
      unit.add_image(image)

      # img2 was deleted, img3 is added
      image = Roomorama::Image.new("unit1img3")
      image.url = "https://www.example.org/img3"
      unit.add_image(image)
    end
  }

  subject { described_class.new(original_unit, new_unit) }

  it "generates a unit diff, including image changes" do
    diff = subject.extract_diff

    expect(diff).to be_a Roomorama::Diff::Unit
    expect(diff.to_h).to eq({
      identifier:  "unit1",
      description: "Largest Unit Available, including a private garden",
      floor:       nil,

      images: {
        create: [
          {
            identifier: "unit1img3",
            url:        "https://www.example.org/img3"
          }
        ],
        update: [
          {
            identifier: "unit1img1",
            caption:    "Swimming Pool, heated water"
          }
        ],
        delete: ["unit1img2"]
      }
    })
  end
end
