require 'spec_helper'

RSpec.describe Avantio::Mappers::RoomoramaProperty do
  include Support::Fixtures

  let(:accommodation_with_all_services) { accommodation_from_file('avantio/accommodation_with_all_services.xml') }

  it 'returns mapped property' do
    property = subject.build(accommodation_with_all_services)

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
  end

  def accommodation_from_file(filename)
    Avantio::Mappers::Accommodation.new.build(xml_from_file(filename).at_xpath('AccommodationData'))
  end

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end
