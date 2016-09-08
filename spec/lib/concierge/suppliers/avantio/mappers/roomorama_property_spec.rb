require 'spec_helper'

RSpec.describe Avantio::Mappers::RoomoramaProperty do
  include Support::Fixtures

  let(:accommodation_with_all_services) { accommodation_from_file('avantio/accommodation_with_all_services.xml') }
  let(:description) { description_from_file('avantio/description.xml') }
  let(:occupational_rule) { occupational_rule_from_file('avantio/occupational_rule_with_not_actual_seasons.xml') }
  let(:rate) { rate_from_file('avantio/rate.xml') }

  let(:description_text) {
    'The apartment in Benidorm  has capacity for 4 people. <br>'\
    'The apartment is nicely furnished, is newly constructed. <br>'\
    'The house is situated in an animated neighborhood next to the sea.<br>'\
    'The accommodation is equipped with the following things: iron, safe, '\
    'air conditioning (heat/cold), air conditioned in the whole house, '\
    'communal swimming pool, garage, tv, stereo.<br>In the induction open'\
    ' plan kitchen, refrigerator, oven, freezer, washing machine and dryer are provided.'
  }

  before do
    allow(Date).to receive(:today).and_return(Date.new(2016, 6, 25))
  end

  it 'returns mapped property' do
    property = subject.build(accommodation_with_all_services, description, occupational_rule, rate, 365)

    expect(property).to be_a(Roomorama::Property)
    expect(property.identifier).to eq('128498|1416325650|itsvillas')
    expect(property.title).to eq('Villa Gemma')
    expect(property.type).to eq('house')
    expect(property.subtype).to eq('villa')
    expect(property.address).to eq('virgen del manzano, 10')
    expect(property.postal_code).to eq('46001')
    expect(property.city).to eq('Gerona')
    expect(property.number_of_bedrooms).to eq(1)
    expect(property.max_guests).to eq(1)
    expect(property.apartment_number).to be nil
    expect(property.neighborhood).to eq('Sin especificar')
    expect(property.country_code).to eq('ES')
    expect(property.lat).to eq('39.4742')
    expect(property.lng).to eq('-0.380721')
    expect(property.default_to_available).to be false
    expect(property.number_of_bathrooms).to be_nil
    expect(property.floor).to be nil
    expect(property.number_of_double_beds).to be_nil
    expect(property.number_of_single_beds).to be_nil
    expect(property.number_of_sofa_beds).to eq(1)
    expect(property.surface).to be_nil
    expect(property.surface_unit).to be_nil
    expect(property.pets_allowed).to be true
    expect(property.currency).to eq('EUR')
    expect(property.cancellation_policy).to eq('super_elite')
    expect(property.security_deposit_amount).to eq(1000.0)
    expect(property.security_deposit_type).to eq('cash')
    expect(property.security_deposit_currency_code).to eq('EUR')
    expect(property.services_cleaning).to be true
    expect(property.services_cleaning_rate).to eq(20)
    expect(property.services_cleaning_required).to be true
    expect(property.amenities).to eq(['bed_linen_and_towels', 'internet', 'parking', 'airconditioning',
                                      'wheelchairaccess', 'pool', 'balcony', 'outdoor_space'])

    expect(property.images.length).to eq(2)
    image = property.images.first
    expect(image.identifier).to eq 'a137aae770da77859b6a60e0f8ac5624'
    expect(image.url).to eq 'http://img.crs.itsolutions.es/fotos/1258485483aea4571d97cbf40fc90373c2a0883e23/12584854836f07364bd3aaa7a7e6e977f89438ce8a.jpg'

    expect(property.description).to eq(description_text)
    expect(property.minimum_stay).to eq(2)
    expect(property.nightly_rate).to eq(299)
    expect(property.weekly_rate).to eq(2093)
    expect(property.monthly_rate).to eq(8970)
  end

  def accommodation_from_file(filename)
    Avantio::Mappers::Accommodation.new.build(xml_from_file(filename).at_xpath('AccommodationData'))
  end

  def description_from_file(filename)
    Avantio::Mappers::Description.new.build(xml_from_file(filename).at_xpath('AccommodationItem'))
  end

  def occupational_rule_from_file(filename)
    Avantio::Mappers::OccupationalRule.new.build(xml_from_file(filename).at_xpath('OccupationalRule'))
  end

  def rate_from_file(filename)
    Avantio::Mappers::Rate.new.build(xml_from_file(filename).at_xpath('AccommodationRS'))
  end

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end
