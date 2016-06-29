require 'spec_helper'

RSpec.describe Ciirus::SpecialOptions do
  it 'sets the default values' do
    search = described_class.new
    expect(search.xml_msg).to be_empty
    expect(search.json_msg).to be_empty
  end

  describe '#to_xml' do

    let(:xml_msg) { Nokogiri::XML.fragment('<foo>bar</foo>') }
    let(:json_msg) { Nokogiri::XML.fragment('{"foo": "bar"}') }

    it 'generates the appropriate xml message' do
      filter = described_class.new(xml_msg: xml_msg, json_msg: json_msg)
      filter_xml = Nokogiri::XML::Builder.new do |xml|
        xml.root do
          filter.to_xml(xml)
        end
      end
      filter_xml = filter_xml.doc
      expect(filter_xml.at_xpath('//xmlMsg/foo').text).to eq 'bar'
      expect(filter_xml.at_xpath('//jSonMsg').text).to eq '{"foo": "bar"}'
    end

    it 'generates default xml message' do
      filter = described_class.new
      filter_xml = Nokogiri::XML::Builder.new do |xml|
        xml.root do
          filter.to_xml(xml)
        end
      end
      filter_xml = filter_xml.doc
      expect(filter_xml.at_xpath('//xmlMsg').text).to be_empty
      expect(filter_xml.at_xpath('//jSonMsg').text).to be_empty
    end
  end
end
