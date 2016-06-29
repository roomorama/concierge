require 'spec_helper'

RSpec.describe Ciirus::SearchOptions do
  it 'sets the default values' do
    search = Ciirus::SearchOptions.new
    expect(search.top_x).to eq(0)
    expect(search.full_details).to eq(true)
    expect(search.quote).to eq(false)
    expect(search.pool_heat).to eq(false)
  end

  describe '.to_xml' do

    it 'generates the appropriate xml message' do
      filter = Ciirus::SearchOptions.new(top_x: 3, full_details: false, quote: true, pool_heat: true)
      filter_xml = Nokogiri::XML::Builder.new do |xml|
        filter.to_xml(xml)
      end
      filter_xml = filter_xml.doc
      expect(filter_xml.at_xpath('//ReturnTopX').text).to eq '3'
      expect(filter_xml.at_xpath('//ReturnFullDetails').text).to eq 'false'
      expect(filter_xml.at_xpath('//ReturnQuote').text).to eq 'true'
      expect(filter_xml.at_xpath('//IncludePoolHeatInQuote').text).to eq 'true'
    end
  end
end
