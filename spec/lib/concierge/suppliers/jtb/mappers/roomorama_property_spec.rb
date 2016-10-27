require 'spec_helper'

RSpec.describe JTB::Mappers::RoomoramaProperty do
  include Support::JTB::Factories

  let(:hotel) { create_hotel }

  let(:today) { Date.new(2016, 10, 8) }

  before do
    allow(Date).to receive(:today).and_return(today)
  end

  it 'returns mapped roomorama property entity' do
    create_lookup
    create_picture
    room = create_room_type
    create_picture({ sequence: 2, room_code: room.room_code })
    create_lookup({ category: '4', id: room.room_grade, name: 'Standard'})
    create_room_amenities_lookups
    create_rate_plan
    create_rate_plan({ rate_plan_id: 'CHUHW0101TRP2PSG'})
    create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG' })
    create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG', service_date: '2016-10-11' })
    create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG', service_date: '2016-10-12', number_of_units: 0 })
    create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG', service_date: '2016-10-13', sale_status: '1' })
    create_room_stock
    create_room_stock({ service_date: '2016-10-11' })
    create_room_stock({ service_date: '2016-10-12', number_of_units: 0 })
    create_room_stock({ service_date: '2016-10-13', sale_status: '1' })
    create_room_price
    create_room_price({ date: '2016-10-11', room_rate: 9010.0 })
    create_room_price({ date: '2016-10-12', room_rate: 8010.0 })
    create_room_price({ date: '2016-10-13', room_rate: 7010.0 })
    create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG' })
    create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG', date: '2016-10-11', room_rate: 9011.0 })
    create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG', date: '2016-10-12', room_rate: 8011.0 })
    create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG', date: '2016-10-13', room_rate: 7011.0 })

    result = subject.build(hotel)

    expect(result).to be_a(Result)
    expect(result.success?).to be true

    property = result.value

    expect(property).to be_a(Roomorama::Property)
    expect(property.identifier).to eq('6440013')
    expect(property.instant_booking).to be true
    expect(property.multi_unit).to be true
    expect(property.title).to eq('Hotel Nikko Himeji')
    expect(property.type).to eq('apartment')
    expect(property.address).to eq('100 Minamiekimae-cho, Himeji-shi, Hyogo Prefecture, 510-0075')
    expect(property.postal_code).to eq('510-0075')
    expect(property.city).to eq('Kinki')
    expect(property.description).to eq("This large city hotel is located in front of JR Himeji Station's south exit and features a large capacity banquet hall.")
    expect(property.check_in_time).to eq('10:00')
    expect(property.check_out_time).to eq('11:30')
    expect(property.default_to_available).to be false
    expect(property.minimum_stay).to eq(1)
    expect(property.currency).to eq('JPY')
    expect(property.cancellation_policy).to eq('super_elite')
    expect(property.lat).to eq('34.82536445833334')
    expect(property.lng).to eq('134.69021241666667')
    expect(property.units.length).to eq(1)

    expect(property.images.length).to eq(1)
    image = property.images.first
    expect(image.identifier).to eq('45abfcbf754f38144899b2f30467aadd')
    expect(image.url).to eq('https://www.jtbgenesis.com/image/GMTGEWEB01/CHUW01/64400131000000063.jpg')
    expect(image.position).to eq(1)

    unit = property.units[0]
    expect(unit.identifier).to eq('SGL|CHUHW01RM0000001')
    expect(unit.title).to eq('Single A')
    expect(unit.description).to eq('Room Grade: Standard. Room Type: Single.')
    expect(unit.nightly_rate).to eq(9010.0)
    expect(unit.weekly_rate).to eq(63070.0)
    expect(unit.monthly_rate).to eq(270300.0)
    expect(unit.number_of_bedrooms).to eq(1)
    expect(unit.number_of_units).to eq(1)
    expect(unit.number_of_single_beds).to eq(1)
    expect(unit.number_of_double_beds).to be_nil
    expect(unit.number_of_sofa_beds).to be_nil
    expect(unit.surface).to eq(15.1)
    expect(unit.surface_unit).to eq('metric')
    expect(unit.amenities).to eq([:airconditioning, :tv, :internet, :breakfast, :bed_linen_and_towels, :outdoor_space])
    expect(unit.max_guests).to eq(1)
    expect(unit.minimum_stay).to eq(1)
    expect(unit.smoking_allowed).to be true

    expect(unit.images.length).to eq(1)
    image = unit.images.first
    expect(image.identifier).to eq('45abfcbf754f38144899b2f30467aadd')
    expect(image.url).to eq('https://www.jtbgenesis.com/image/GMTGEWEB01/CHUW01/64400131000000063.jpg')
    expect(image.position).to eq(2)
  end

  context 'when coordinates have unexpected format' do
    let(:hotel) { create_hotel({ latitude: 'bar', longitude: 'foo' }) }

    it 'returns property with nil coordinates' do
      create_lookup
      create_picture
      room = create_room_type
      create_picture({ sequence: 2, room_code: room.room_code })
      create_lookup({ category: '4', id: room.room_grade, name: 'Standard'})
      create_room_amenities_lookups
      create_rate_plan
      create_rate_plan({ rate_plan_id: 'CHUHW0101TRP2PSG'})
      create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG' })
      create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG', service_date: '2016-10-11' })
      create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG', service_date: '2016-10-12', number_of_units: 0 })
      create_room_stock({ rate_plan_id: 'CHUHW0101TRP2PSG', service_date: '2016-10-13', sale_status: '1' })
      create_room_stock
      create_room_stock({ service_date: '2016-10-11' })
      create_room_stock({ service_date: '2016-10-12', number_of_units: 0 })
      create_room_stock({ service_date: '2016-10-13', sale_status: '1' })
      create_room_price
      create_room_price({ date: '2016-10-11', room_rate: 9010.0 })
      create_room_price({ date: '2016-10-12', room_rate: 8010.0 })
      create_room_price({ date: '2016-10-13', room_rate: 7010.0 })
      create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG' })
      create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG', date: '2016-10-11', room_rate: 9011.0 })
      create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG', date: '2016-10-12', room_rate: 8011.0 })
      create_room_price({ rate_plan_id: 'CHUHW0101TRP2PSG', date: '2016-10-13', room_rate: 7011.0 })

      result = subject.build(hotel)

      expect(result).to be_a(Result)
      expect(result.success?).to be true

      property = result.value
      expect(property.lat).to be_nil
      expect(property.lng).to be_nil
    end
  end

  it 'returns error when property does not have images' do
    create_lookup

    result = subject.build(hotel)

    expect(result).to be_a(Result)
    expect(result.success?).to be false
    expect(result.error.code).to eq :empty_images
    expect(result.error.data).to eq 'Property images list is empty'
  end

  it 'returns error when property does not nightly rate' do
    create_lookup
    create_picture

    result = subject.build(hotel)

    expect(result).to be_a(Result)
    expect(result.success?).to be false
    expect(result.error.code).to eq :unknown_nightly_rate
    expect(result.error.data).to eq 'No one of property units has prices information'
  end

end