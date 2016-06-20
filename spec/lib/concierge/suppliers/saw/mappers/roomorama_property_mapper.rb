require "spec_helper"
require "pry"

RSpec.describe SAW::Mappers::RoomoramaProperty do
  let(:basic_property) do
    SAW::Entities::BasicProperty.new(
      internal_id: 1234,
      type: 'apartment',
      title: 'Title Basic',
      lon: '10',
      lat: '20',
      currency_code: 'RUB',
      country_code: 'RUS',
      nightly_rate: '10',
      weekly_rate: '70',
      monthly_rate: '300',
      description: 'Description Basic',
      city: 'City Basic',
      neighborhood: 'Neighborhood Basic',
      multi_unit: true
    )
  end

  let(:detailed_property) do
    SAW::Entities::DetailedProperty.new(
      internal_id: 9876,
      type: 'house',
      title: 'Title Detailed',
      lon: '90',
      lat: '80',
      description: 'Description Detailed',
      city: 'City Detailed',
      neighborhood: 'Neighborhood Detailed',
      address: 'Address',
      country: 'Thailand',
      amenities: ['wifi', 'breakfast'],
      not_supported_amenities: ['foo', 'bar']
    )
  end
    
  it "returns roomorama property entity" do
    property = described_class.build(basic_property, detailed_property)
    expect(property).to be_a(Roomorama::Property)
  end
    
  it "adds multi-unit flag" do
    property = described_class.build(basic_property, detailed_property)
    expect(property.multi_unit?).to eq(basic_property.multi_unit?)
  end
    
  it "adds to result property needed attributes from basic property" do
    property = described_class.build(basic_property, detailed_property)

    attributes = %i(
      type
      title
      country_code
      nightly_rate
      weekly_rate
      monthly_rate
    )

    expect(property.identifier).to eq(basic_property.internal_id)
    expect(property.currency).to eq(basic_property.currency_code)
    expect(property.lat).to eq(basic_property.lat)
    expect(property.lng).to eq(basic_property.lon)

    attributes.each do |attr|
      expect(property.send(attr)).to eq(basic_property.send(attr))
    end
  end
    
  it "adds to result property needed attributes from detailed property" do
    property = described_class.build(basic_property, detailed_property)

    attributes = %i(
      description
      city
      neighborhood
      address
      amenities
    )
    
    #TODO: not_supported_amenities

    attributes.each do |attr|
      expect(property.send(attr)).to eq(detailed_property.send(attr))
    end
  end
end
