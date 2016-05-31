require "spec_helper"

RSpec.describe Workers::Comparison::Image do
  let(:original_images) {
    [
      Roomorama::Image.load({
        identifier: "img1",
        url:        "https://www.example.org/image1.png",
        caption:    "Swimming Pool"
      }),
      Roomorama::Image.load({
        identifier: "img2",
        url:        "https://www.example.org/image2.png",
        caption:    "Barbecue Pit"
      }),
      Roomorama::Image.load({
        identifier: "img3",
        url:        "https://www.example.org/image3.png",
        caption:    "Meeting Room"
      }),
      Roomorama::Image.load({
        identifier: "img4",
        url:        "https://www.example.org/image4.png",
        caption:    "Entrace"
      }),
      Roomorama::Image.load({
        identifier: "img5",
        url:        "https://www.example.org/image5.png",
        caption:    nil
      })
    ]
  }

  let(:new_images) {
    [
      Roomorama::Image.load({
        identifier: "img1",
        url:        "https://www.example.org/image1.png",
        caption:    "Swimming Pool, with set of chairs"
      }),
      Roomorama::Image.load({
        identifier: "img2",
        url:        "https://www.example.org/image2.png",
        caption:    "Barbecue Pit"
      }),
      Roomorama::Image.load({
        identifier: "img5",
        url:        "https://www.example.org/image5.png",
        caption:    "Customer Service"
      }),
      Roomorama::Image.load({
        identifier: "img6",
        url:        "https://www.example.org/image6.png",
        caption:    "Foosball Table"
      })
    ]
  }

  subject { described_class.new(original_images, new_images) }

  it "generates a diff of the list of images, including additions, removals and changes" do
    diff = subject.extract_diff

    expect(diff).to have_key :create
    expect(diff).to have_key :update
    expect(diff).to have_key :delete

    created = diff[:create]
    expect(created.size).to eq 1

    image = created.first
    expect(image).to be_a Roomorama::Image
    expect(image.identifier).to eq "img6"
    expect(image.url).to eq "https://www.example.org/image6.png"
    expect(image.caption).to eq "Foosball Table"

    updated = diff[:update]
    expect(updated.size).to eq 2

    image_diff = updated.first
    expect(image_diff).to be_a Roomorama::Diff::Image
    expect(image_diff.identifier).to eq "img1"
    expect(image_diff.caption).to eq "Swimming Pool, with set of chairs"

    image_diff = updated.last
    expect(image_diff).to be_a Roomorama::Diff::Image
    expect(image_diff.identifier).to eq "img5"
    expect(image_diff.caption).to eq "Customer Service"

    deleted = diff[:delete]
    expect(deleted).to eq ["img3", "img4"]
  end

  it "does not include one operation if there are no elements" do
    original_images << Roomorama::Image.load({
      identifier: "img6",
      url:        "https://www.example.org/image6.png",
      caption:    "Foosball Table"
    })

    expect(subject.extract_diff).not_to have_key :create
  end
end
