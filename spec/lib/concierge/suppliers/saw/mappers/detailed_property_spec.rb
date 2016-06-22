require 'spec_helper'

module SAW
  RSpec.describe Mappers::DetailedProperty do
    let(:country_name) { 'Thailand' }
    let(:image_url_rewrite) { false }
    let(:hash) do
      {
        "name"=>"Outrigger Laguna Phuket Resort & Villas",
        "image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39050",
        "country"=>"Thailand",
        "location"=>"Golf Course",
        "city_region"=>"Phuket",
        "checkin_time"=>"3:00PM",
        "checkout_time"=>"11:00AM",
        "phone"=>"111111111",
        "fax"=>"2222222",
        "email"=>"reservations@mansleyapartments.com",
        "postalcode"=>"83110",
        "rooms"=>nil,
        "flag_breakfast_included"=>"N",
        "cancellation_message"=>"A cancellation period of 25 days applies",
        "cancellation_days"=>"25",
        "our_rating"=>{"our_rating_value"=>"10", "our_rating_description"=>"SUPERIOR PLUS"},
        "customer_rating"=>nil,
        "property_description"=>
         "Villas provide private homes with kitchen, dining and living areas on lower floor and bedrooms on the upper floor.  Pool villas feature lap pools and Thai sala pavilions.\n\nSuites provide contemporary single-level and dual-level suites adjacent to the main reception, swimming pool, Kids Club, and Panache restaurant. Suites do not include a washing machine in the apartment.  \n\nPartake of all that Laguna Phuket provides, superb beaches, exquisite spas, exceptional dining, and simply great golf.\n\nIf staying the night of 31st December there is a compulsory NYE Gala Dinner at THB 5,500.00 per adult and THB 2,750.00 per child up to the age of 12.\n\nExtra beds can be added to each apartment at an additional cost.",
        "accommodations"=>
         {"accommodation_type"=>
           [{"accommodation_name"=>"All", "@id"=>"-1"},
            {"accommodation_name"=>"1-Bedroom", "@id"=>"95"},
            {"accommodation_name"=>"2 Bedroom - 1 Bathroom", "@id"=>"96"},
            {"accommodation_name"=>"3 Bedroom - 2 Bathroom", "@id"=>"99"},
            {"accommodation_name"=>"4 Bedroom - 3 Bathroom", "@id"=>"103"}]},
        "beddingconfigurations"=>
         {"property_accommodation"=>
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
             "@id"=>"10257"}]},
        "property_accommodations"=>
         {"accommodation_type"=>
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
             "@id"=>"103"}]},
        "propertyimportantpoints"=>nil,
        "facility_services"=>
         {"facility_service"=>
           ["24 Hour Emergency Contact",
            "24 Hour Reception/Concierge",
            "Air-Conditioning/Cooling",
            "Alarm Clock",
            "Answer Phones",
            "Baby Amenities",
            "Babysitting (On Request)",
            "Bar",
            "Bathroom Welcome Pack",
            "BBQ",
            "Breakfast Room",
            "Burners / Hobs",
            "Chauffeur Service (Extra Cost)",
            "Childrens' Playground",
            "Coffee Maker",
            "Coffee Shop Nearby",
            "Conference Facilities",
            "Deposit Box",
            "Digital TV",
            "Direct Dial Telephone",
            "Dry Cleaning (Extra Cost)",
            "DVD Player",
            "Fitness Centre On-Site",
            "Freeview TV",
            "Fridge / Freezer",
            "Garden",
            "Hairdryer",
            "Ipod Docking Station",
            "Iron and Ironing Board",
            "Kettle",
            "Laundry Facilities On-Site",
            "Lift",
            "Maid Service Daily",
            "No Smoking Apartments/Rooms",
            "Oven ",
            "Parking On-Site",
            "Restaurant Nearby",
            "Restaurant On-Site",
            "Room Safe",
            "Room Service",
            "Shuttle Services",
            "Sports Facilities",
            "Supermarket On-Site",
            "Swimming Pool Outdoors",
            "Tea and Coffee",
            "Toaster",
            "Washing Machine / Dryer",
            "WIFI Free of Charge",
            "WIFI Reception Area Free of Charge",
            "Work Place"]},
        "local_attractions"=>{"local_attraction"=>"Laguna Phuket Golf Club"},
        "image_gallery"=>
         {"image"=>
           [{"title"=>"1 Bedroom Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=38990",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=38992"},
            {"title"=>"1 Bedroom Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=38995",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=38997"},
            {"title"=>"1 Bedroom Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39000",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39002"},
            {"title"=>"1 Bedroom Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39005",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39007"},
            {"title"=>"2 Bedroom Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39010",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39012"},
            {"title"=>"2 Bedroom Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39015",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39017"},
            {"title"=>"2 Bedroom Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39020",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39022"},
            {"title"=>"3 Bedroom Pool Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39025",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39027"},
            {"title"=>"3 Bedroom Pool Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39030",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39032"},
            {"title"=>"3 Bedroom Pool Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39035",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39037"},
            {"title"=>"3 Bedroom Pool Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39045",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39047"},
            {"title"=>"3 Bedroom Pool Suite",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39050",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39052"},
            {"title"=>"Outrigger Laguna Phuket Resort & Villas",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39055",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39057"},
            {"title"=>"Outrigger Laguna Phuket Resort & Villas",
             "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39060",
             "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39062"}]},
        "map_location"=>{"latitude"=>"8.00382", "longitude"=>"98.30736", "full_address"=>"Address1 Address2 Phuket Thailand"},
        "@id"=>"2893"
      }
    end

    it "returns detailed property entity" do
      property = described_class.build(hash)
      expect(property).to be_a(SAW::Entities::DetailedProperty)
    end

    it "adds internal_id" do
      property = described_class.build(hash)
      expect(property.internal_id).to eq(hash["@id"].to_i)
    end

    it "adds a room type" do
      property = described_class.build(hash)
      expect(property.type).to eq('apartment')
    end

    it "adds a title" do
      property = described_class.build(hash)
      expect(property.title).to eq(hash["name"])
    end

    it "adds a description" do
      property = described_class.build(hash)
      expect(property.description).to eq(hash["property_description"])
    end

    it "adds address coordinates" do
      property = described_class.build(hash)
      expect(property.lat).to eq("8.00382")
      expect(property.lon).to eq("98.30736")
    end

    it "adds city, country, neighborhood and full_address" do
      property = described_class.build(hash)
      expect(property.city).to eq("Phuket")
      expect(property.country).to eq("Thailand")
      expect(property.address).to eq("Address1 Address2 Phuket Thailand")
      expect(property.neighborhood).to eq("Golf Course")
    end

    it "adds amenities" do
      property = described_class.build(hash)
      expect(property.amenities).to eq(
        %w(airconditioning tv gym laundry free_cleaning parking wifi)
      )
    end
    
    it "doesn't add breakfast to amenities if it's not available" do
      hash["flag_breakfast_included"] = "N"

      property = described_class.build(hash)
      expect(property.amenities).to eq(
        %w(airconditioning tv gym laundry free_cleaning parking wifi)
      )
    end

    it "adds breakfast to amenities if available" do
      hash["flag_breakfast_included"] = "Y"

      property = described_class.build(hash)
      expect(property.amenities).to eq(
        %w(airconditioning tv gym laundry free_cleaning parking wifi breakfast)
      )
    end
    
    it "has empty amenities when facility services equal nil" do
      hash["facility_services"] = nil

      property = described_class.build(hash)
      expect(property.amenities).to eq([])
    end
    
    it "has empty amenities when facility services equal {}" do
      hash["facility_services"] = {}

      property = described_class.build(hash)
      expect(property.amenities).to eq([])
    end

    it "adds not supported amenities" do
      property = described_class.build(hash)
      expect(property.not_supported_amenities).to eq(
        ["24 Hour Emergency Contact",
         "24 Hour Reception/Concierge",
         "Alarm Clock",
         "Answer Phones",
         "Baby Amenities",
         "Babysitting (On Request)",
         "Bar",
         "Bathroom Welcome Pack",
         "BBQ",
         "Breakfast Room",
         "Burners / Hobs",
         "Chauffeur Service (Extra Cost)", 
         "Childrens' Playground", 
         "Coffee Maker", 
         "Coffee Shop Nearby", 
         "Conference Facilities", 
         "Deposit Box", 
         "Direct Dial Telephone", 
         "Dry Cleaning (Extra Cost)", 
         "Fridge / Freezer", 
         "Garden", 
         "Hairdryer", 
         "Ipod Docking Station", 
         "Iron and Ironing Board", 
         "Kettle", 
         "Lift", 
         "No Smoking Apartments/Rooms", 
         "Oven ", 
         "Restaurant Nearby", 
         "Restaurant On-Site", 
         "Room Safe", 
         "Room Service", 
         "Shuttle Services", 
         "Sports Facilities", 
         "Supermarket On-Site", 
         "Swimming Pool Outdoors", 
         "Tea and Coffee", 
         "Toaster", 
         "Washing Machine / Dryer",
         "Work Place"
        ]
      )
    end

    it "adds multi-unit flag" do
      property = described_class.build(hash)
      expect(property.multi_unit?).to be_truthy
    end

    it "adds images" do
      property = described_class.build(hash)

      expect(property.images).to be_kind_of(Array)
      expect(property.images.size).to eq(14)
      expect(property.images).to all(be_kind_of(Roomorama::Image))
    end

    it "adds bedding configurations" do
      property = described_class.build(hash)

      expect(property.bed_configurations).to eq(hash["beddingconfigurations"])
    end
    
    it "adds property accomodations" do
      property = described_class.build(hash)

      expect(property.property_accommodations).to eq(
        hash["property_accommodations"]
      )
    end
  end
end
