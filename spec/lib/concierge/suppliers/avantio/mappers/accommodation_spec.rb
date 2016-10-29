require 'spec_helper'

RSpec.describe Avantio::Mappers::Accommodation do
  include Support::Fixtures

  let(:accommodation_with_all_services) { xml_from_file('avantio/accommodation_with_all_services.xml').at_xpath('AccommodationData') }

  it 'returns mapped accommodation' do
    accommodation = subject.build(accommodation_with_all_services)

    expect(accommodation).to be_a(Avantio::Entities::Accommodation)
    expect(accommodation.property_id).to eq('128498|1416325650|itsvillas')
    expect(accommodation.name).to eq('Villa Gemma')
    expect(accommodation.ga_code).to eq('739')
    expect(accommodation.security_deposit_amount).to eq(1000.0)
    expect(accommodation.security_deposit_type).to eq('cash')
    expect(accommodation.security_deposit_currency_code).to eq('EUR')
    expect(accommodation.occupational_rule_id).to eq('204')
    expect(accommodation.master_kind_code).to eq('2')
    expect(accommodation.country_iso_code).to eq('ES')
    expect(accommodation.city).to eq('Gerona / Girona')
    expect(accommodation.lat).to eq('39.4742')
    expect(accommodation.lng).to eq('-0.380721')
    expect(accommodation.district).to eq('Sin especificar')
    expect(accommodation.postal_code).to eq('46001')
    expect(accommodation.street).to eq('virgen del manzano')
    expect(accommodation.number).to eq('10')
    expect(accommodation.block).to eq('')
    expect(accommodation.door).to be nil
    expect(accommodation.floor).to be nil
    expect(accommodation.currency).to eq('EUR')
    expect(accommodation.people_capacity).to eq(1)
    expect(accommodation.minimum_occupation).to eq(1)
    expect(accommodation.bedrooms).to eq(1)
    expect(accommodation.double_beds).to be_nil
    expect(accommodation.individual_beds).to be_nil
    expect(accommodation.individual_sofa_beds).to eq(1)
    expect(accommodation.double_sofa_beds).to be_nil
    expect(accommodation.housing_area).to be_nil
    expect(accommodation.area_unit).to eq('m')
    expect(accommodation.bathtub_bathrooms).to be_nil
    expect(accommodation.shower_bathrooms).to be_nil
    expect(accommodation.pool_type).to eq('comunitaria')
    expect(accommodation.tv).to be false
    expect(accommodation.fire_place).to be false
    expect(accommodation.garden).to be false
    expect(accommodation.bbq).to be false
    expect(accommodation.terrace).to be true
    expect(accommodation.fenced_plot).to be false
    expect(accommodation.elevator).to be false
    expect(accommodation.dvd).to be false
    expect(accommodation.balcony).to be true
    expect(accommodation.gym).to be false
    expect(accommodation.handicapped_facilities).to eq('apta-discapacitados')
    expect(accommodation.internet).to be true
    expect(accommodation.pets_allowed).to be true
    expect(accommodation.services_cleaning).to be true
    expect(accommodation.services_cleaning_rate).to eq(20)
    expect(accommodation.services_cleaning_required).to be true
    expect(accommodation.bed_linen).to be true
    expect(accommodation.towels).to be true
    expect(accommodation.parking).to be true
    expect(accommodation.airconditioning).to be true
    expect(accommodation.check_in_rules).to eq("Check-in time:\n  anytime")
    expect(accommodation.check_out_time).to eq('01:00')
  end

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end
