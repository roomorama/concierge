require 'spec_helper'

RSpec.describe Avantio::Mappers::Services do
  include Support::Fixtures

  let(:accommodation_with_deposit) { xml_from_file('avantio/accommodation_with_deposit.xml').at_xpath('AccommodationData') }

  it 'returns mapped services' do
    services = subject.build(accommodation_with_deposit)

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

  # TODO empty xml
  # TODO not all the season
  # TODO bad structure

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end
