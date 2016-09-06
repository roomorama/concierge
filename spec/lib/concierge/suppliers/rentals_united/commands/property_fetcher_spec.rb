require "spec_helper"

RSpec.describe RentalsUnited::Commands::PropertyFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:property_id) { "1234" }
  let(:location) do
    double(
      id: '1505',
      city: 'Paris',
      neighborhood: 'Ile-de-France',
      country: 'France',
      currency: 'EUR'
    )
  end
  let(:subject) { described_class.new(credentials, property_id, location) }
  let(:url) { credentials.url }

  it "returns an error if property does not exist" do
    stub_data = read_fixture("rentals_united/properties/not_found.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_property
    expect(result).not_to be_success
    expect(result.error.code).to eq("56")

    event = Concierge.context.events.last.to_h
    expect(event[:message]).to eq(
      "Response indicating the Status with ID `56`, and description ``"
    )
    expect(event[:backtrace]).to be_kind_of(Array)
    expect(event[:backtrace].any?).to be true
  end

  context "when response contains property data" do
    let(:file_name) { "rentals_united/properties/property.xml" }

    before do
      stub_data = read_fixture(file_name)
      stub_call(:post, url) { [200, {}, stub_data] }
    end

    let(:property) do
      result = subject.fetch_property
      expect(result).to be_success

      result.value
    end

    it "returns property object" do
      expect(property).to be_kind_of(Roomorama::Property)
    end

    it "sets id to the property" do
      expect(property.identifier).to eq("519688")
    end

    it "sets title to the property" do
      expect(property.title).to eq("Test property")
    end

    it "sets type to the property" do
      expect(property.type).to eq("house")
    end

    it "sets subtype to the property" do
      expect(property.subtype).to eq("villa")
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

    it "sets en description to the property" do
      expect(property.description).to eq("Test description")
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
      expect(property.cancellation_policy).to eq("super_strict")
    end

    it "sets default_to_available flag" do
      expect(property.default_to_available).to eq(true)
    end

    it "does not set multi-unit flag" do
      expect(property.multi_unit).to eq(false)
    end

    it "sets instant_booking flag" do
      expect(property.instant_booking?).to eq(true)
    end

    context "when multiple descriptions are available" do
      let(:file_name) { "rentals_united/properties/property_with_multiple_descriptions.xml" }

      it "sets en description to the property" do
        expect(property.description).to eq("Yet another one description")
      end
    end

    context "when no available descriptions" do
      let(:file_name) { "rentals_united/properties/property_without_descriptions.xml" }

      it "sets description to nil" do
        expect(property.description).to be_nil
      end
    end

    context "when mapping amenities" do
      it "adds amenities to property" do
        expect(property.amenities).to eq(
          ["bed_linen_and_towels", "airconditioning", "pool", "wheelchairaccess", "elevator", "parking"]
        )
      end

      context "and when there is no amenities" do
        let(:file_name) { "rentals_united/properties/property_without_amenities.xml" }

        it "sets empty amenities" do
          expect(property.amenities).to eq([])
        end
      end
    end

    context "when mapping single image to property" do
      let(:file_name) { "rentals_united/properties/property_with_one_image.xml" }

      let(:expected_images) do
        {
          "a0c68acc113db3b58376155c283dfd59" => {
            url: "https://dwe6atvmvow8k.cloudfront.net/ru/427698/519688/636082399089701851.jpg",
            caption: 'Main image'
          }
        }
      end

      it "adds array of with one image to the property" do
        expect(property.images.size).to eq(1)
        expect(property.images).to all(be_kind_of(Roomorama::Image))
        expect(property.images.map(&:identifier)).to eq(expected_images.keys)

        property.images.each do |image|
          expect(image.url).to eq(expected_images[image.identifier][:url])
          expect(image.caption).to eq(expected_images[image.identifier][:caption])
        end
      end
    end

    context "when mapping multiple images to property" do
      let(:expected_images) do
        {
          "62fc304eb20a25669b84d2ca2ea61308" => {
            url: "https://dwe6atvmvow8k.cloudfront.net/ru/427698/519688/636082398988145159.jpg",
            caption: 'Interior'
          },
          "a0c68acc113db3b58376155c283dfd59" => {
            url: "https://dwe6atvmvow8k.cloudfront.net/ru/427698/519688/636082399089701851.jpg",
            caption: 'Main image'
          }
        }
      end

      it "adds array of images to the property" do
        expect(property.images.size).to eq(2)
        expect(property.images).to all(be_kind_of(Roomorama::Image))
        expect(property.images.map(&:identifier)).to eq(expected_images.keys)

        property.images.each do |image|
          expect(image.url).to eq(expected_images[image.identifier][:url])
          expect(image.caption).to eq(expected_images[image.identifier][:caption])
        end
      end
    end

    context "when there is no images for property" do
      let(:file_name) { "rentals_united/properties/property_without_images.xml" }

      it "returns an empty array for property images" do
        expect(property.images).to eq([])
      end
    end
  end

  context "when response from the api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/bad_xml.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_property

      expect(result).not_to be_success
      expect(result.error.code).to eq(:unrecognised_response)

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq(
        "Error response could not be recognised (no `Status` tag in the response)"
      )
      expect(event[:backtrace]).to be_kind_of(Array)
      expect(event[:backtrace].any?).to be true
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:post, url) { raise Faraday::TimeoutError }

      result = subject.fetch_property

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
