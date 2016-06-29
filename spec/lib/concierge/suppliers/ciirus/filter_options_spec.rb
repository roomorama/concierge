require 'spec_helper'

RSpec.describe Ciirus::FilterOptions do

  it 'sets the default values' do
    filter = Ciirus::FilterOptions.new(management_company_id: 123)
    expect(filter.management_company_id).to eq(123)
    expect(filter.property_id).to eq(0)
  end

  it 'builds filter options with default values' do
    filter = Ciirus::FilterOptions.new
    expect(filter.filters.has_pool).to be(2)
    expect(filter.filters.has_spa).to be(2)
  end

  it 'builds filter options with the given values' do
    filter = Ciirus::FilterOptions.new do |filters|
      filters.has_pool = 1
      filters.has_spa = 0
      filters.sleeps = 5
    end
    expect(filter.filters.has_pool).to be(1)
    expect(filter.filters.has_spa).to be(0)
    expect(filter.filters.is_gas_free).to be(false)
    expect(filter.filters.sleeps).to be(5)
  end

  describe '.to_xml' do

    it 'generates the appropriate xml message' do
      filter = Ciirus::FilterOptions.new(management_company_id: 123, property_id: 4435)
      filter_xml = Nokogiri::XML::Builder.new do |xml|
        filter.to_xml(xml)
      end
      filter_xml = filter_xml.doc
      expect(filter_xml.at_xpath('//ManagementCompanyID').text).to eq '123'
      expect(filter_xml.at_xpath('//CommunityID').text).to eq '0'
      expect(filter_xml.at_xpath('//PropertyID').text).to eq '4435'
      expect(filter_xml.at_xpath('//PropertyType').text).to eq('0')
      expect(filter_xml.at_xpath('//HasPool').text).to eq('2')
      expect(filter_xml.at_xpath('//HasSpa').text).to eq('2')
      expect(filter_xml.at_xpath('//PrivacyFence').text).to eq('2')
      expect(filter_xml.at_xpath('//CommunalGym').text).to eq('2')
      expect(filter_xml.at_xpath('//HasGamesRoom').text).to eq('2')
      expect(filter_xml.at_xpath('//IsGasFree').text).to eq('false')
      expect(filter_xml.at_xpath('//Sleeps').text).to eq('0')
      expect(filter_xml.at_xpath('//Bedrooms').text).to eq('0')
      expect(filter_xml.at_xpath('//PropertyClass').text).to eq('0')
      expect(filter_xml.at_xpath('//ConservationView').text).to eq('2')
      expect(filter_xml.at_xpath('//WaterView').text).to eq('2')
      expect(filter_xml.at_xpath('//LakeView').text).to eq('2')
      expect(filter_xml.at_xpath('//WiFi').text).to eq('2')
      expect(filter_xml.at_xpath('//PetsAllowed').text).to eq('2')
      expect(filter_xml.at_xpath('//OnGolfCourse').text).to eq('2')
      expect(filter_xml.at_xpath('//SouthFacingPool').text).to eq('2')
    end
  end
end