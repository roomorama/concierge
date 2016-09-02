require 'spec_helper'

RSpec.describe Avantio::Mappers::Description do
  include Support::Fixtures

  let(:description_xml) { xml_from_file('avantio/description.xml').at_xpath('AccommodationItem') }
  let(:images) do
    %w(http://img.crs.itsolutions.es/fotos/1258485483aea4571d97cbf40fc90373c2a0883e23/12584854836f07364bd3aaa7a7e6e977f89438ce8a.jpg
       http://img.crs.itsolutions.es/fotos/1258485483aea4571d97cbf40fc90373c2a0883e23/1258485484da3be6e237044109158d21d1a7544821.jpg)
  end
  let(:description_text) do
    'The <b>apartment in Benidorm</b>  has capacity for 4 people. <br>'\
    'The apartment is nicely furnished, is newly constructed. <br>The house is '\
    'situated in an animated neighborhood next to the sea.<br>The accommodation '\
    'is equipped with the following things: iron, safe, air conditioning (heat/cold), '\
    'air conditioned in the whole house, communal swimming pool, garage, tv, stereo.'\
    '<br>In the induction open plan kitchen, refrigerator, oven, freezer, washing'\
    '&nbsp;machine and dryer are provided.'
  end

  it 'returns mapped description' do
    description = subject.build(description_xml)

    expect(description).to be_a(Avantio::Entities::Description)
    expect(description.property_id).to eq('60505|1238513302|itsalojamientos')
    expect(description.images).to eq(images)
    expect(description.description).to eq(description_text)
  end

  def xml_from_file(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end
