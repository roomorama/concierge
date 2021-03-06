require 'spec_helper'

RSpec.describe THH::Mappers::RoomoramaProperty do
  include Support::Fixtures

  let(:raw_property) { parsed_property('thh/properties_response.xml') }
  let(:length) { 365 }
  let(:description) do
    "This modern tropical five-bedroom house at Jomtein is the holiday home of your dreams. Picture relaxing in your private swimming pool minutes from the best amenities and facilities Jomtein has to offer. With a hire car inclusive in our attractive rates, you can be at the beach within minutes, be it Jomtein or Pattaya.\n\n"\
      " Crossing the finely landscaped gardens, and entering this property through a set of French doors, the occupant is greeted by a stylish, modern decor theme, which is repeated throughout the entire villa. The large lounge, which incorporates a spacious dining area, runs the full length of the property. A well-equipped modern kitchen,"\
      " with black granite worktops, is tucked away in a separate room, with easy access to the dining area. Moving upstairs, three of the four bedrooms seem to vie for the title of “Master Bedroom”, each being elegantly decorated and entirely comfortable, with their own en-suite wet rooms. This is a beautiful holiday property, "\
      "decorated in a fun and fresh style, a wonderful home away from home in which to enjoy your vacation. Conveniently close to all of the major amenities, in the quite gated community of Viewpoint, just a few minutes from the beach. \n\n"\
      "The living area is light and spacious with modern furnishings, seating for eight persons with Cable TV, DVD/CD player and separate radio / CD player, please note this player will not accept copy CD’s. The living area opens to a dining facility for six persons.\n\n"\
      "Fully fitted with granite worktops and tiled floors, appliances include fridge/freezer, microwave, oven, cooker, rice cooker, toaster and all utensils. There are place settings for eight people. A washing machine is available at the covered utility area. Iron and ironing board are also provided.\n\n"\
      "Bedroom 1 Queen-size bed with ample furniture. Bedroom 2 Queen-size bed with ample furniture. Bedroom 3 Queen-size bed with ample furniture. Bedroom 4 Queen-size bed with ample furniture.\n\n"\
      "Bedroom 1 offers a full bathroom - bedrooms 2 &amp; 3 have good size shower rooms with toilet and wash hand basins. There is a cloakroom off the living area for your convenience."
  end
  let(:amenities) do
    ['kitchen', 'wifi', 'cabletv', 'parking', 'airconditioning', 'laundry', 'pool', 'balcony', 'outdoor_space', 'gym', 'bed_linen_and_towels']
  end
  let(:today) { Date.new(2016, 12, 10) }

  before do
    allow(Date).to receive(:today).and_return(today)
  end

  describe '#build' do
    it 'returns mapped roomorama property' do
      result = subject.build(raw_property)

      expect(result).to be_a(Result)
      expect(result).to be_success
      property = result.value
      expect(property.identifier).to eq('15')
      expect(property.default_to_available).to be false
      expect(property.type).to eq('house')
      expect(property.subtype).to eq('villa')
      expect(property.title).to eq('Baan Duan Chai')
      expect(property.city).to eq('Pattaya')
      expect(property.description).to eq(description)
      expect(property.number_of_bedrooms).to eq('5')
      expect(property.max_guests).to eq('10')
      expect(property.country_code).to eq('TH')
      expect(property.lat).to eq('12.884067')
      expect(property.lng).to eq('100.896267')
      expect(property.number_of_bathrooms).to eq('5')
      expect(property.number_of_double_beds).to eq('4')
      expect(property.number_of_single_beds).to be_nil
      expect(property.number_of_sofa_beds).to eq('2')
      expect(property.amenities).to eq(amenities)
      expect(property.currency).to eq('THB')
      expect(property.cancellation_policy).to eq('strict')

      expect(property.description_append).to eq "Electricity allowance: 100 KW/day. Additional charge on exceeding the allowance: 7 THB/KW"
      expect(property.de.description_append).to eq "Inklusive Stromverbrauch von: 100 KW/Tag. Zuschlaggebühr für höheren Verbrauch von: 7 THB/KW"
      expect(property.es.description_append).to eq "Electricidad: 100 KW/día. Cargo adicional por exceder la asignación: 7 THB/KW"
      expect(property.zh.description_append).to eq "电费：100 KW /天。 超过津贴的额外费用：7 THB/KW "
      expect(property.zh_tw.description_append).to eq "電費：100 KW /天。超過津貼的額外費用：7 THB/KW"

      expect(property.images.length).to eq(21)
      image = property.images.first
      expect(image.identifier).to eq 'db41cdc9d16bd1504daffedbc2652de9'
      expect(image.url).to eq 'http://img.thailandholidayhomes.com/cache/villa_15_6863-530x354-1.jpg'

      expect(property.minimum_stay).to eq(3)
      expect(property.nightly_rate).to eq(8510.0)
      expect(property.weekly_rate).to eq(59570.0)
      expect(property.monthly_rate).to eq(255300.0)

      expect(property.security_deposit_amount).to eq(10000.0)
      expect(property.security_deposit_currency_code).to eq('THB')
      expect(property.security_deposit_type).to eq('cash')

      expect(property.check_in_time).to eq('13:00')
      expect(property.check_out_time).to eq('11:00')
    end

    context 'when no available days' do
      let(:raw_property) { parsed_property('thh/properties_without_available_days_response.xml') }
      let(:today) { Date.new(2016, 11, 14) }

      it 'returns an error' do
        result = subject.build(raw_property)

        expect(result).to be_a(Result)
        expect(result.success?).to eq false
        expect(result.error.code).to eq :no_available_dates
        expect(result.error.data).to eq 'All available days of the property are booked'
      end
    end

    context 'when no electricty information' do
      let(:raw_property) { parsed_property('thh/properties_without_electricity_info.xml') }

      it 'returns empty description_append' do
        result = subject.build(raw_property)

        expect(result).to be_a(Result)
        expect(result.success?).to eq true
        expect(result.value.description_append).to be_nil
      end
    end

    context 'when electricity shows free' do
      let(:raw_property) {
        parsed_property('thh/properties_response.xml').
          merge({
            "additional_information" => {
              "free_electricity" => "free KW/day",
              "electricity_over" => "7 THB/KW"
            }
        })
      }

      it 'returns empty description_append' do
        expect(raw_property.get('additional_information.free_electricity')).to eq "free KW/day"
        expect(raw_property.get('additional_information.electricity_over')).to_not be_nil
        result = subject.build(raw_property)

        expect(result).to be_a(Result)
        expect(result.success?).to eq true
        expect(result.value.description_append).to be_nil
      end
    end
  end

  def parsed_property(name)
    parser = Nori.new(advanced_typecasting: false)
    response = parser.parse(read_fixture(name))['response']
    Concierge::SafeAccessHash.new(response['property'])
  end
end
