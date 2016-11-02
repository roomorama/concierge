require 'spec_helper'

RSpec.describe Avantio::Mappers::Availability do
  include Support::Fixtures

  let(:availability_xml) { xml_from_file('avantio/availability.xml').at_xpath('AccommodationRS') }

  it 'returns mapped availability' do
    availability = subject.build(availability_xml)

    expect(availability).to be_a(Avantio::Entities::Availability)
    expect(availability.property_id).to eq('70931|1276860135|itsalojamientos')
    expect(availability.occupational_rule_id).to eq('204')
    expect(availability.periods.length).to eq(2)

    period_one = availability.periods[0]
    expect(period_one.start_date).to eq(Date.new(2010, 6, 18))
    expect(period_one.end_date).to eq(Date.new(2016, 9, 11))
    expect(period_one.available?).to be_truthy

    period_two = availability.periods[1]
    expect(period_two.start_date).to eq(Date.new(2016, 9, 12))
    expect(period_two.end_date).to eq(Date.new(2016, 9, 16))
    expect(period_two.available?).to be_falsey
  end

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end
