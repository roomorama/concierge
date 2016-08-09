require 'spec_helper'

RSpec.describe Ciirus::Mappers::RoomoramaProperty do

  let(:amenities) do
    ['airconditioning', 'gym', 'internet', 'outdoor_space', 'parking',
     'pool', 'tv', 'wifi']
  end
  let(:country) { 'UK' }
  let(:property) do
    Ciirus::Entities::Property.new(
      {
        property_id: '33680',
        property_name: "Mandy's Magic Villa",
        address: '1234 Dahlia Reserve Drive',
        zip: '34744',
        city: 'Kissimmee',
        bedrooms: 6,
        sleeps: 6,
        min_nights_stay: 0,
        type: 'Villa',
        country: country,
        xco: '28.2238577',
        yco: '-81.4975719',
        bathrooms: 4,
        king_beds: 1,
        queen_beds: 2,
        full_beds: 3,
        twin_beds: 4,
        extra_bed: true,
        sofa_bed: true,
        pets_allowed: true,
        currency_code: 'USD',
        amenities: amenities
      }
    )
  end
  let(:images) { ['http://image.com/15252'] }
  let(:rates) do
    [
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2014, 6, 27),
        DateTime.new(2014, 8, 22),
        3,
        157.50
      ),
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2014, 8, 23),
        DateTime.new(2014, 10, 16),
        2,
        141.43
      )
    ]
  end
  let(:security_deposit) do
    Ciirus::Entities::Extra.new(
      {
        property_id: '33692',
        item_code: 'SD',
        item_description: 'Security Deposit',
        flat_fee: true,
        flat_fee_amount: 2500.00,
        daily_fee: false,
        daily_fee_amount: 0,
        percentage_fee: false,
        percentage: 0,
        mandatory: true,
        minimum_charge: 0.00,
      }
    )
  end
  let(:description) { 'Some description string' }

  subject { described_class.new }

  it 'returns mapped roomorama property entity' do
    roomorama_property = subject.build(property, images, rates, description, security_deposit)

    expect(roomorama_property).to be_a(Roomorama::Property)
    expect(roomorama_property.identifier).to eq('33680')
    expect(roomorama_property.type).to eq('house')
    expect(roomorama_property.subtype).to eq('villa')
    expect(roomorama_property.title).to eq("Mandy's Magic Villa")
    expect(roomorama_property.address).to eq('1234 Dahlia Reserve Drive')
    expect(roomorama_property.postal_code).to eq('34744')
    expect(roomorama_property.city).to eq('Kissimmee')
    expect(roomorama_property.description).to eq(description)
    expect(roomorama_property.number_of_bedrooms).to eq(6)
    expect(roomorama_property.max_guests).to eq(6)
    expect(roomorama_property.country_code).to eq('GB')
    expect(roomorama_property.lat).to eq('28.2238577')
    expect(roomorama_property.lng).to eq('-81.4975719')
    expect(roomorama_property.number_of_bathrooms).to eq(4)
    expect(roomorama_property.number_of_double_beds).to eq(6)
    expect(roomorama_property.number_of_single_beds).to eq(5)
    expect(roomorama_property.number_of_sofa_beds).to eq(1)
    expect(roomorama_property.amenities).to eq(amenities)
    expect(roomorama_property.pets_allowed).to be(true)
    expect(roomorama_property.currency).to eq('USD')
    expect(roomorama_property.cancellation_policy).to eq('super_elite')

    expect(roomorama_property.images.length).to eq(1)
    image = roomorama_property.images.first
    expect(image.identifier).to eq '7055ced3ea87d8c220f99595c483dfe3'
    expect(image.url).to eq 'http://image.com/15252'

    expect(roomorama_property.minimum_stay).to eq(2)
    expect(roomorama_property.nightly_rate).to eq(141.43)
    expect(roomorama_property.weekly_rate).to eq(990.01)
    expect(roomorama_property.monthly_rate).to eq(4242.9)

    expect(roomorama_property.security_deposit_amount).to eq(2500.0)
    expect(roomorama_property.security_deposit_currency_code).to eq('USD')
    expect(roomorama_property.security_deposit_type).to eq('unknown')
  end

  it 'works fine if security_deposit is nil' do
    roomorama_property = subject.build(property, images, rates, description, nil)

    expect(roomorama_property.security_deposit_amount).to be_nil
    expect(roomorama_property.security_deposit_currency_code).to be_nil
    expect(roomorama_property.security_deposit_type).to be_nil
  end

  context 'when country is unknown' do
    let(:country) { '1568799' }
    it 'doesnot fill the country code' do
      roomorama_property = subject.build(property, images, rates, description, security_deposit)

      expect(roomorama_property.country_code).to be_nil
    end
  end
end
