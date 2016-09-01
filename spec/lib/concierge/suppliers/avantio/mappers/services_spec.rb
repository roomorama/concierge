require 'spec_helper'

RSpec.describe Avantio::Mappers::Services do
  include Support::Fixtures

  let(:accommodation_with_all_services) { xml_from_file('avantio/accommodation_with_all_services.xml').at_xpath('AccommodationData') }
  let(:accommodation_with_not_all_year_services) { xml_from_file('avantio/accommodation_with_not_all_year_services.xml').at_xpath('AccommodationData') }
  let(:accommodation_without_services) { xml_from_file('avantio/accommodation_without_services.xml').at_xpath('AccommodationData') }

  it 'returns mapped services' do
    services = subject.build(accommodation_with_all_services)

    expect(services[:security_deposit_amount]).to eq(1000.0)
    expect(services[:security_deposit_type]).to eq('cash')
    expect(services[:security_deposit_currency_code]).to eq('EUR')

    expect(services[:internet]).to be true

    expect(services[:pets_allowed]).to be true

    expect(services[:services_cleaning]).to be true
    expect(services[:services_cleaning_rate]).to eq(20)
    expect(services[:services_cleaning_required]).to be true

    expect(services[:bed_linen]).to be true
    expect(services[:towels]).to be true

    expect(services[:parking]).to be true

    expect(services[:airconditioning]).to be true
  end

  it 'returns empty services for empty xml' do
    services = subject.build(accommodation_without_services)

    expect(services.length).to eq(0)
  end

  it 'does not return services without full season' do
    services = subject.build(accommodation_with_not_all_year_services)

    expect(services.length).to eq(0)
  end

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end
