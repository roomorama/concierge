require 'spec_helper'

RSpec.describe Avantio::Mappers::Rate do
  include Support::Fixtures

  let(:rate_xml) { xml_from_file('avantio/rate.xml').at_xpath('AccommodationRS') }

  it 'returns mapped rate' do
    rate = subject.build(rate_xml)

    expect(rate).to be_a(Avantio::Entities::Rate)
    expect(rate.property_id).to eq('55706|1210069498|itsalojamientos')
    expect(rate.periods.length).to eq(2)

    period_one = rate.periods[0]
    expect(period_one[:start_date]).to eq(Date.new(2015, 6, 4))
    expect(period_one[:end_date]).to eq(Date.new(2018, 7, 10))
    expect(period_one[:rate]).to eq(299)

    period_two = rate.periods[1]
    expect(period_two[:start_date]).to eq(Date.new(2022, 6, 1))
    expect(period_two[:end_date]).to eq(Date.new(2022, 8, 31))
    expect(period_two[:rate]).to eq(10)
  end

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end
