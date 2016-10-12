module Support
  module JTB

    # +Support::JTB::Factories+
    #
    # This module provides a collection of methods for easily creating JTB
    # entities. For each method, a set of defaults is assumed, which can be
    # overwritten by passing a hash of attributes to each of them.
    module Factories
      def create_hotel(overrides = {})
        attributes = {
          language: "EN",
          city_code: "CHU",
          hotel_code: "W01",
          jtb_hotel_code: "6440013",
          hotel_name: "Hotel Nikko Himeji",
          location_code: "63",
          hotel_description: "This large city hotel is located in front of JR Himeji Station's south exit and features a large capacity banquet hall.",
          latitude: "N34.49.31.31205",
          longitude: "E134.41.24.7647",
          hotel_type: "H",
          address: "100 Minamiekimae-cho, Himeji-shi, Hyogo Prefecture, 510-0075",
          non_smoking_room: "1",
          parking: "1",
          internet: "1",
          wifi: "0",
          indoor_pool_free: "0",
          indoor_pool_charged: "1",
          outdoor_pool_free: "0",
          outdoor_pool_charged: "0",
          indoor_gym_free: "0",
          indoor_gym_charged: "0",
          outdoor_gym_free: "0",
          outdoor_gym_charged: "0",
          wheelchair_access: "1"
        }.merge(overrides)

        hotel = ::JTB::Entities::Hotel.new(attributes)
        ::JTB::Repositories::HotelRepository.create(hotel)
      end

      def create_lookup(overrides = {})
        attributes = {
          id: "63",
          language: "EN",
          category: "1",
          related_id: nil,
          name: "Kinki (Other areas) / Mie (Ise / Shima)"
        }.merge(overrides)

        ::JTB::Repositories::LookupRepository.upsert(attributes)
      end

      def create_picture(overrides = {})
        attributes = {
          language: "EN",
          city_code: "CHU",
          hotel_code: "W01",
          sequence: 1,
          category: "101",
          room_code: nil,
          url: "GMTGEWEB01/CHUW01/64400131000000063.jpg",
          comments: nil
        }.merge(overrides)

        picture = ::JTB::Entities::Picture.new(attributes)
        ::JTB::Repositories::PictureRepository.create(picture)
      end

      def create_rate_plan(overrides = {})
        attributes = {
          city_code: "CHU",
          hotel_code: "W01",
          rate_plan_id: "CHUHW0101TRP1PSG",
          room_code: "CHUHW01RM0000001",
          meal_plan_code: "RMO",
          occupancy: "1"
        }.merge(overrides)

        rate_plan = ::JTB::Entities::RatePlan.new(attributes)
        ::JTB::Repositories::RatePlanRepository.create(rate_plan)
      end

      def create_room_price(overrides = {})
        attributes = {
          city_code: "CHU",
          hotel_code: "W01",
          rate_plan_id: "CHUHW0101TRP1PSG",
          date: "2016-10-10",
          room_rate: 10100.0
        }.merge(overrides)

        room_price = ::JTB::Entities::RoomPrice.new(attributes)
        ::JTB::Repositories::RoomPriceRepository.create(room_price)
      end

      def create_room_stock(overrides = {})
        attributes = {
          city_code: "CHU",
          hotel_code: "W01",
          rate_plan_id: "CHUHW0101TRP1PSG",
          service_date: "2016-10-10",
          number_of_units: 1,
          closing_date: "20161008",
          sale_status: "1",
          reservation_closing_date: "20161008"
        }.merge(overrides)

        room_stock = ::JTB::Entities::RoomStock.new(attributes)
        ::JTB::Repositories::RoomStockRepository.create(room_stock)
      end

      def create_room_type(overrides = {})
        attributes = {
          language: "EN",
          city_code: "CHU",
          hotel_code: "W01",
          room_code: "CHUHW01RM0000001",
          room_grade: "STD",
          room_type_code: "SGL",
          room_name: "Single A",
          min_guests: 1,
          max_guests: 1,
          extra_bed: nil,
          extra_bed_type: nil,
          size1: "15.10",
          size2: nil,
          size3: nil,
          size4: nil,
          size5: nil,
          size6: nil,
          amenities: "100 0000010111011011101000000001000000010010000001000000101110010000001100000010111 11 01000010000  "
        }.merge(overrides)

        room_type = ::JTB::Entities::RoomType.new(attributes)
        ::JTB::Repositories::RoomTypeRepository.create(room_type)
      end

      def create_room_amenities_lookups
        amenities_lookups = [
          { language: 'EN', category: '19', id: '001', name: 'Bath' },
          { language: 'EN', category: '19', id: '002', name: 'Bath w/ L-shaped handrail' },
          { language: 'EN', category: '19', id: '003', name: 'Rental shower chair' },
          { language: 'EN', category: '19', id: '004', name: 'Bath w/ hot spring water' },
          { language: 'EN', category: '19', id: '005', name: 'Bath w/ heated water' },
          { language: 'EN', category: '19', id: '006', name: 'Shower booth' },
          { language: 'EN', category: '19', id: '007', name: 'Open-air bath' },
          { language: 'EN', category: '19', id: '008', name: 'Open-air bath w/ hot spring water' },
          { language: 'EN', category: '19', id: '009', name: 'Open-air bath w/ heated water' },
          { language: 'EN', category: '19', id: '010', name: 'Restroom' },
          { language: 'EN', category: '19', id: '011', name: 'Japanese style toilet' },
          { language: 'EN', category: '19', id: '012', name: 'Western style toilet' },
          { language: 'EN', category: '19', id: '013', name: 'Washlet toilet' },
          { language: 'EN', category: '19', id: '014', name: 'Air conditioning' },
          { language: 'EN', category: '19', id: '015', name: 'Air conditioning to charge' },
          { language: 'EN', category: '19', id: '016', name: 'Air conditioning for free' },
          { language: 'EN', category: '19', id: '017', name: 'Heating' },
          { language: 'EN', category: '19', id: '018', name: 'Heating to charge' },
          { language: 'EN', category: '19', id: '019', name: 'Heating for free' },
          { language: 'EN', category: '19', id: '020', name: 'Refrigerator' },
          { language: 'EN', category: '19', id: '021', name: 'TV' },
          { language: 'EN', category: '19', id: '022', name: 'TV to charge' },
          { language: 'EN', category: '19', id: '023', name: 'TV for free' },
          { language: 'EN', category: '19', id: '024', name: 'Pay TV' },
          { language: 'EN', category: '19', id: '025', name: 'Pay TV (check-out payment)' },
          { language: 'EN', category: '19', id: '026', name: 'Pay TV (prepaid card)' },
          { language: 'EN', category: '19', id: '027', name: 'VCR' },
          { language: 'EN', category: '19', id: '028', name: 'DVD player' },
          { language: 'EN', category: '19', id: '029', name: 'CD player' },
          { language: 'EN', category: '19', id: '030', name: 'Safe-deposit box' },
          { language: 'EN', category: '19', id: '031', name: 'Safe-deposit box to charge' },
          { language: 'EN', category: '19', id: '032', name: 'Safe-deposit box for free' },
          { language: 'EN', category: '19', id: '033', name: 'FAX' },
          { language: 'EN', category: '19', id: '034', name: 'Pants press' },
          { language: 'EN', category: '19', id: '035', name: 'Balcony (porch)' },
          { language: 'EN', category: '19', id: '036', name: 'Non-smoking' },
          { language: 'EN', category: '19', id: '037', name: 'Wheelchair (doorway over 80cm)' },
          { language: 'EN', category: '19', id: '038', name: 'Horigotatsu (footwarmer built into floor), table' },
          { language: 'EN', category: '19', id: '039', name: 'Emergency buzzer' },
          { language: 'EN', category: '19', id: '040', name: 'Internet' },
          { language: 'EN', category: '19', id: '041', name: 'Rental PC' },
          { language: 'EN', category: '19', id: '042', name: 'Rental PC to charge' },
          { language: 'EN', category: '19', id: '043', name: 'Rental PC for free' },
          { language: 'EN', category: '19', id: '044', name: 'Rental bath board' },
          { language: 'EN', category: '19', id: '045', name: 'In-room dinner' },
          { language: 'EN', category: '19', id: '046', name: 'Dinner in private dining room' },
          { language: 'EN', category: '19', id: '047', name: 'Dinner at irori fire place' },
          { language: 'EN', category: '19', id: '048', name: 'Dinner at restaurant' },
          { language: 'EN', category: '19', id: '049', name: 'Dinner in banquet hall' },
          { language: 'EN', category: '19', id: '050', name: 'Dinner buffet' },
          { language: 'EN', category: '19', id: '051', name: 'Dinner at in-house theater' },
          { language: 'EN', category: '19', id: '052', name: 'In-room breakfast' },
          { language: 'EN', category: '19', id: '053', name: 'Breakfast in the private dining room' },
          { language: 'EN', category: '19', id: '054', name: 'Breakfast at irori fire place' },
          { language: 'EN', category: '19', id: '055', name: 'Breakfast at restaurant' },
          { language: 'EN', category: '19', id: '056', name: 'Breakfast in banquet hall' },
          { language: 'EN', category: '19', id: '057', name: 'Breakfast buffet' },
          { language: 'EN', category: '19', id: '058', name: 'Breakfast at in-house theater' },
          { language: 'EN', category: '19', id: '059', name: 'Toothbrush' },
          { language: 'EN', category: '19', id: '060', name: 'Towel' },
          { language: 'EN', category: '19', id: '061', name: 'Bath towel' },
          { language: 'EN', category: '19', id: '062', name: 'Hand towel' },
          { language: 'EN', category: '19', id: '063', name: 'Bathrobe' },
          { language: 'EN', category: '19', id: '064', name: 'Yukata (Japanese bathrobe)' },
          { language: 'EN', category: '19', id: '065', name: "Women's yukata (Japanese bathrobe) selectable" },
          { language: 'EN', category: '19', id: '066', name: 'Pajamas' },
          { language: 'EN', category: '19', id: '067', name: 'Samue (Japanese traditional work style)' },
          { language: 'EN', category: '19', id: '068', name: 'Yukata (Japanese bathrobe) for child' },
          { language: 'EN', category: '19', id: '069', name: 'Pajamas for child' },
          { language: 'EN', category: '19', id: '070', name: 'Hairbrush' },
          { language: 'EN', category: '19', id: '071', name: 'Shampoo & conditioner' },
          { language: 'EN', category: '19', id: '072', name: 'Body soap' },
          { language: 'EN', category: '19', id: '073', name: 'Shower cap' },
          { language: 'EN', category: '19', id: '074', name: 'Hair slide' },
          { language: 'EN', category: '19', id: '075', name: 'Face wash' },
          { language: 'EN', category: '19', id: '076', name: 'Cleansing' },
          { language: 'EN', category: '19', id: '077', name: 'Lotion' },
          { language: 'EN', category: '19', id: '078', name: 'Emulsion' },
          { language: 'EN', category: '19', id: '079', name: 'Razor' },
          { language: 'EN', category: '19', id: '080', name: "Men's cosmetics" },
          { language: 'EN', category: '19', id: '081', name: 'Hair dryer' },
          { language: 'EN', category: '19', id: '082', name: 'Evening paper' },
          { language: 'EN', category: '19', id: '083', name: 'Evening paper to charge' },
          { language: 'EN', category: '19', id: '084', name: 'Evening paper for free' },
          { language: 'EN', category: '19', id: '085', name: 'Morning paper' },
          { language: 'EN', category: '19', id: '086', name: 'Morning paper to charge' },
          { language: 'EN', category: '19', id: '087', name: 'Morning paper for free' },
          { language: 'EN', category: '19', id: '088', name: 'Sea' },
          { language: 'EN', category: '19', id: '089', name: 'Mountain' },
          { language: 'EN', category: '19', id: '090', name: 'River' },
          { language: 'EN', category: '19', id: '091', name: 'Lake' },
          { language: 'EN', category: '19', id: '092', name: 'Valley' },
          { language: 'EN', category: '19', id: '093', name: 'Garden' },
          { language: 'EN', category: '19', id: '094', name: 'Night view' },
          { language: 'EN', category: '19', id: '095', name: 'Port' },
          { language: 'EN', category: '19', id: '096', name: 'Rural district' },
          { language: 'EN', category: '19', id: '097', name: 'Waterfall' },
          { language: 'EN', category: '19', id: '098', name: 'Forest' }
        ]
        amenities_lookups.each do |amenity|
          create_lookup(amenity)
        end
      end
    end
  end
end
