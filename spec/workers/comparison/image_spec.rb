require "spec_helper"

RSpec.describe Workers::Comparison::Image do
  let(:original_images) {
    [
      {
        identifier: "img1",
        url:        "https://www.example.org/image1.png",
        caption:    "Swimming Pool"
      },
      {
        identifier: "img2",
        url:        "https://www.example.org/image2.png",
        caption:    "Barbecue Pit"
      },
      {
        identifier: "img3",
        url:        "https://www.example.org/image3.png",
        caption:    "Meeting Room"
      },
      {
        identifier: "img4",
        url:        "https://www.example.org/image4.png",
        caption:    "Entrace"
      },
      {
        identifier: "img5",
        url:        "https://www.example.org/image5.png",
        caption:    nil
      }
    ].map { |hash| Concierge::SafeAccessHash.new(hash) }
  }

  let(:new_images) {
    [
      {
        identifier: "img1",
        url:        "https://www.example.org/image1.png",
        caption:    "Swimming Pool, with set of chairs"
      },
      {
        identifier: "img2",
        url:        "https://www.example.org/image2.png",
        caption:    "Barbecue Pit"
      },
      {
        identifier: "img5",
        url:        "https://www.example.org/image5.png",
        caption:    "Customer Service"
      },
      {
        identifier: "img6",
        url:        "https://www.example.org/image6.png",
        caption:    "Foosball Table"
      }
    ].map { |hash| Concierge::SafeAccessHash.new(hash) }
  }

  subject { described_class.new(original_images, new_images) }

  it "generates a diff of the list of images, including additions, removals and changes" do
    expect(subject.extract_diff).to eq({
      create: [
        safe_access({
          identifier: "img6",
          url:        "https://www.example.org/image6.png",
          caption:    "Foosball Table"
        })
      ],
      update: [
        safe_access({
          identifier: "img1",
          caption:    "Swimming Pool, with set of chairs"
        }),
        safe_access({
          identifier: "img5",
          caption:    "Customer Service"
        })
      ],
      delete: ["img3", "img4"]
    })
  end

  it "does not include one operation if there are no elements" do
    original_images << {
      identifier: "img6",
      url:        "https://www.example.org/image6.png",
      caption:    "Foosball Table"
    }

    expect(subject.extract_diff).to eq({
      update: [
        safe_access({
          identifier: "img1",
          caption:    "Swimming Pool, with set of chairs"
        }),
        safe_access({
          identifier: "img5",
          caption:    "Customer Service"
        })
      ],
      delete: ["img3", "img4"]
    })
  end

  private

  def safe_access(hash)
    Concierge::SafeAccessHash.new(hash)
  end
end
