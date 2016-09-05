require 'spec_helper'

RSpec.describe Avantio::Mappers::OccupationalRule do
  include Support::Fixtures

  let(:occupational_rule_xml) { xml_from_file('avantio/occupational_rule.xml').at_xpath('OccupationalRule') }

  it 'returns mapped occupational rule' do
    occupational_rule = subject.build(occupational_rule_xml)

    expect(occupational_rule).to be_a(Avantio::Entities::OccupationalRule)
    expect(occupational_rule.id).to eq('204')
    expect(occupational_rule.seasons.length).to eq(2)

    season_one = occupational_rule.seasons[0]
    expect(season_one[:start_date]).to eq(Date.new(2016, 6, 21))
    expect(season_one[:end_date]).to eq(Date.new(2016, 12, 31))
    expect(season_one[:min_nights]).to eq(1)

    season_two = occupational_rule.seasons[1]
    expect(season_two[:start_date]).to eq(Date.new(2017, 1, 1))
    expect(season_two[:end_date]).to eq(Date.new(2017, 12, 31))
    expect(season_two[:min_nights]).to eq(1)
  end

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end
