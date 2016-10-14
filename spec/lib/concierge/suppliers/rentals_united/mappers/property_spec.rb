require "spec_helper"

RSpec.describe RentalsUnited::Mappers::Property do
  include Support::Fixtures

  let(:file_name) { "rentals_united/properties/property.xml" }
  let(:property_hash) do
    stub_data = read_fixture(file_name)
    safe_hash = RentalsUnited::ResponseParser.new.to_hash(stub_data)
    safe_hash.get("Pull_ListSpecProp_RS.Property")
  end

  let(:subject) { described_class.new(property_hash) }
  let(:property) { subject.build_property }

  context "when hash contains property data" do
    it "builds property object" do
      expect(property).to be_kind_of(RentalsUnited::Entities::Property)
    end

    it "sets id to the property" do
      expect(property.id).to eq("519688")
    end

    it "sets title to the property" do
      expect(property.title).to eq("Test property")
    end

    it "sets property_type_id to the property" do
      expect(property.property_type_id).to eq("35")
    end

    it "sets max_guests to the property" do
      expect(property.max_guests).to eq(2)
    end

    it "sets bedroom_type_id to the property" do
      expect(property.bedroom_type_id).to eq("4")
    end

    it "sets surface to the property" do
      expect(property.surface).to eq(39)
    end

    it "sets address information to the property" do
      expect(property.lat).to eq(55.0003426)
      expect(property.lng).to eq(73.2965942999999)
      expect(property.address).to eq("Test street address")
      expect(property.postal_code).to eq("644119")
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

    it "sets active flag to the property" do
      expect(property.active?).to eq(true)
    end

    it "sets archived flag to the property" do
      expect(property.archived?).to eq(false)
    end

    it "sets owner_id to the property" do
      expect(property.owner_id).to eq("427698")
    end

    it "sets security_deposit_type to the property" do
      expect(property.security_deposit_type).to eq("5")
    end

    it "sets security_deposit_amount to the property" do
      expect(property.security_deposit_amount).to eq(5.50)
    end

    it "sets check in instuctions to the property" do
      expect(property.check_in_instructions).to eq(
        "Landlord: Ruslan Sharipov\nEmail: sharipov.reg@gmail.com\nPhone: +79618492980\nDaysBeforeArrival: 1\nPickupService: DetailsOfPickUpService\nHowToArrive: HowToArriveDescription"
      )
    end

    it "sets bed counts" do
      expect(property.number_of_single_beds).to eq(0)
      expect(property.number_of_double_beds).to eq(0)
      expect(property.number_of_sofa_beds).to eq(0)
    end

    context "when property does not have some parts of check_in_instructions" do
      let(:file_name) { "rentals_united/properties/property_with_partial_check_in_instructions.xml" }

      it "sets check in instuctions to contain only existing fields" do
        expect(property.check_in_instructions).to eq(
          "Landlord: Ruslan Sharipov\nDaysBeforeArrival: 1"
        )
      end
    end

    context "when property does not have check_in_instructions" do
      let(:file_name) { "rentals_united/properties/property_without_check_in_instructions.xml" }

      it "sets check in instuctions to be empty" do
        expect(property.check_in_instructions).to eq("")
      end
    end

    context "when property does not have pickup service instructions" do
      let(:file_name) { "rentals_united/properties/property_without_pickup_service.xml" }

      it "sets check in instuctions if some parts are missing" do
        expect(property.check_in_instructions).to eq(
          "Landlord: Ruslan Sharipov\nEmail: sharipov.reg@gmail.com\nPhone: +79618492980\nDaysBeforeArrival: 1\nHowToArrive: HowToArriveDescription"
        )
      end
    end

    context "when property have pickup service instructions in non-en lang" do
      let(:file_name) { "rentals_united/properties/property_with_pickup_service_in_wrong_lang.xml" }

      it "sets check in instuctions if some parts are missing" do
        expect(property.check_in_instructions).to eq(
          "Landlord: Ruslan Sharipov\nEmail: sharipov.reg@gmail.com\nPhone: +79618492980\nDaysBeforeArrival: 1\nHowToArrive: HowToArriveDescription"
        )
      end
    end

    context "when property does not have how to arrive instructions" do
      let(:file_name) { "rentals_united/properties/property_without_how_to_arrive.xml" }

      it "sets check in instuctions if some parts are missing" do
        expect(property.check_in_instructions).to eq(
          "Landlord: Ruslan Sharipov\nEmail: sharipov.reg@gmail.com\nPhone: +79618492980\nDaysBeforeArrival: 1\nPickupService: DetailsOfPickUpService"
        )
      end
    end

    context "when property have how to arrive instructions in non-en lang" do
      let(:file_name) { "rentals_united/properties/property_with_how_to_arrive_in_wrong_lang.xml" }

      it "sets check in instuctions if some parts are missing" do
        expect(property.check_in_instructions).to eq(
          "Landlord: Ruslan Sharipov\nEmail: sharipov.reg@gmail.com\nPhone: +79618492980\nDaysBeforeArrival: 1\nPickupService: DetailsOfPickUpService"
        )
      end
    end

    context "when property is not active" do
      let(:file_name) { "rentals_united/properties/not_active.xml" }

      it "returns not active property" do
        expect(property.active?).to eq(false)
      end
    end

    context "when property is archived" do
      let(:file_name) { "rentals_united/properties/archived.xml" }

      it "returnes archived property" do
        expect(property.archived?).to eq(true)
      end
    end
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

  context "when there is existing amenities for property" do
    let(:file_name) { "rentals_united/properties/property.xml" }

    it "returns an array with property amenities" do
      expect(property.amenities).to eq(
        ["7", "100", "180", "187", "227", "281", "368", "596", "689", "802", "803"]
      )
    end
  end

  context "when there is no amenities for property" do
    let(:file_name) { "rentals_united/properties/property_without_amenities.xml" }

    it "returns an empty array for property amenities" do
      expect(property.amenities).to eq([])
    end
  end

  context "when mapping floors" do
    context "when it's usual floor" do
      let(:file_name) { "rentals_united/properties/property.xml" }

      it "sets floor to the property" do
        expect(property.floor).to eq(3)
      end
    end

    context "when it's Basement encoded by -1000" do
      let(:file_name) { "rentals_united/properties/basement_floor.xml" }

      it "sets floor -1 to the property" do
        expect(property.floor).to eq(-1)
      end
    end
  end

  context "when mapping bathrooms" do
    it "sets number_of_bathrooms field" do
      expect(property.number_of_bathrooms).to eq(4)
    end

    context "when there is no bathrooms" do
      let(:file_name) { "rentals_united/properties/property_without_bathrooms.xml" }

      it "sets number_of_bathrooms to 0" do
        expect(property.number_of_bathrooms).to eq(0)
      end
    end
  end

  context "when mapping single beds" do
    let(:file_name) { "rentals_united/properties/beds/single_beds.xml" }

    it "sets number_of_single_beds" do
      expect(property.number_of_single_beds).to eq(3)
    end
  end

  context "when mapping single beds with extra beds" do
    let(:file_name) { "rentals_united/properties/beds/single_beds_with_extra_beds.xml" }

    it "sets number_of_single_beds" do
      expect(property.number_of_single_beds).to eq(9)
    end
  end

  context "when mapping double beds" do
    let(:file_name) { "rentals_united/properties/beds/double_beds.xml" }

    it "sets number_of_double_beds" do
      expect(property.number_of_double_beds).to eq(5)
    end
  end

  context "when mapping sofa beds" do
    let(:file_name) { "rentals_united/properties/beds/sofa_beds.xml" }

    it "sets number_of_sofa_beds" do
      expect(property.number_of_sofa_beds).to eq(7)
    end
  end

  context "when all types of beds" do
    let(:file_name) { "rentals_united/properties/beds/all_types.xml" }

    it "sets correct numbers of beds" do
      expect(property.number_of_single_beds).to eq(7)
      expect(property.number_of_double_beds).to eq(18)
      expect(property.number_of_sofa_beds).to eq(13)
    end
  end
end
