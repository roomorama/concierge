require 'spec_helper'

RSpec.describe Avantio::Mappers::CheckInRules do
  include Support::Fixtures

  let(:any_time_check_in) { xml_from_file('avantio/accommodation_with_all_services.xml') }

  it 'returns CheckInRules instance' do
    rules = subject.build(any_time_check_in)

    expect(rules).to be_a(Avantio::Entities::CheckInRules)
    expect(rules.rules.length).to eq(1)

    rule = rules.rules[0]
    expect(rule.start_day).to eq(1)
    expect(rule.start_month).to eq(1)
    expect(rule.final_day).to eq(31)
    expect(rule.final_month).to eq(12)
    expect(rule.from).to eq('00:00')
    expect(rule.to).to eq('00:00')
    expect(rule.weekdays).to eq(%w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday))
  end

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename)).at_xpath('AccommodationData')
  end
end
