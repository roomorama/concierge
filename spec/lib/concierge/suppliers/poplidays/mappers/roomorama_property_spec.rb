require 'spec_helper'

RSpec.describe Poplidays::Mappers::RoomoramaProperty do
  include Support::Fixtures

  let(:amenities) do
    ['kitchen', 'tv', 'parking', 'airconditioning', 'laundry',
     'pool', 'elevator', 'outdoor_space']
  end
  let(:property) { {'id' => '8927439190'} }
  let(:details) { JSON.parse(read_fixture('poplidays/property_details2.json')) }
  let(:availabilities) { JSON.parse(read_fixture('poplidays/availabilities_calendar2.json')) }
  let(:description) { "Text here\n\nAnother text here" }
  let(:minimum_details) do
    {
      'type' => 'APARTMENT',
      'address' => {},
      'description' => {},
      'features' => {},
      'photos' => {},
      'mandatoryServicesPrice' => 0
    }
  end

  subject { described_class.new }

  it 'sets default security deposit info for unknown caution' do
    details = minimum_details.merge({'caution' => 'unknown'})
    result = subject.build(property, details, availabilities)

    roomorama_property = result.value
    expect(roomorama_property.security_deposit_amount).to eq(300.0)
    expect(roomorama_property.security_deposit_currency_code).to eq('EUR')
  end

  it 'does not set surface if it is zero' do
    details = minimum_details.merge({'surface' => 0})
    result = subject.build(property, details, availabilities)

    roomorama_property = result.value
    expect(roomorama_property.surface).to be_nil
    expect(roomorama_property.surface_unit).to be_nil
  end

  it 'returns result with mapped roomorama property' do
    result = subject.build(property, details, availabilities)

    expect(result).to be_a(Result)
    expect(result.success?).to be_truthy

    roomorama_property = result.value
    expect(roomorama_property).to be_a(Roomorama::Property)
    expect(roomorama_property.identifier).to eq('8927439190')
    expect(roomorama_property.type).to eq('apartment')
    expect(roomorama_property.subtype).to eq('apartment')
    expect(roomorama_property.title).to eq('Rental Apartment RIVIERA GARDEN - Antibes, 1 bedroom, 4 persons')
    expect(roomorama_property.address).to eq('87-91 Avenue Francisque PERRAUD')
    expect(roomorama_property.postal_code).to eq('06600')
    expect(roomorama_property.city).to eq('Antibes')
    expect(roomorama_property.description).to eq(description)
    expect(roomorama_property.number_of_bedrooms).to eq(1)
    expect(roomorama_property.number_of_bathrooms).to eq(1)
    expect(roomorama_property.max_guests).to eq(4)
    expect(roomorama_property.country_code).to eq('FR')
    expect(roomorama_property.lat).to eq(43.5869881)
    expect(roomorama_property.lng).to eq(7.094132100000024)
    expect(roomorama_property.number_of_bathrooms).to eq(1)
    expect(roomorama_property.amenities).to contain_exactly(*amenities)
    expect(roomorama_property.pets_allowed).to be(true)
    expect(roomorama_property.smoking_allowed).to be(false)
    expect(roomorama_property.currency).to eq('EUR')
    expect(roomorama_property.surface).to eq(45)
    expect(roomorama_property.surface_unit).to eq('metric')
    expect(roomorama_property.cancellation_policy).to eq(Poplidays::Mappers::RoomoramaProperty::CANCELLATION_POLICY)
    expect(roomorama_property.security_deposit_amount).to eq(500.0)
    expect(roomorama_property.security_deposit_currency_code).to eq('EUR')


    expect(roomorama_property.images.length).to eq(3)
    image = roomorama_property.images.first
    expect(image.identifier).to eq '1921aa9638072e815341a09835faba4a'
    expect(image.url).to eq 'http://cdn-prod.poplidays.com/v2/pictures/8927623451-620x465.jpg'

    expect(roomorama_property.minimum_stay).to eq(7)
    expect(roomorama_property.nightly_rate).to eq(78.95)
    expect(roomorama_property.weekly_rate).to eq(552.65)
    expect(roomorama_property.monthly_rate).to eq(2368.5)
  end
end