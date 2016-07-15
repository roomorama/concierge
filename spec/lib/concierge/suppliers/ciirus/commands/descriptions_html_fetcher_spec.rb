require 'spec_helper'

RSpec.describe Ciirus::Commands::DescriptionsHtmlFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://proxy.roomorama.com/ciirus')
  end

  let(:property_id) { 38180 }

  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }
  let(:success_response) { read_fixture('ciirus/responses/descriptions_html_response.xml') }

  subject { described_class.new(credentials) }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(property_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    it 'returns descriptions' do
      stub_call(method: described_class::OPERATION_NAME, response: success_response)

      result = subject.call(property_id)
      expected = 'This Florida vacation LuxuryHome with its own private swimming pool '\
'is located in the exclusive community of Harbour Lakes. This gated community offers '\
'extreme privacy and maximum fun. An oversized swimming pool, and game room will make '\
'your Orlando vacation Dream come true. The Harbour Lakes staff is ready to assist you '\
'with dinner reservations, transportation, etc. Your family will love being only '\
'minutes from Disney.From the moment you step into the plush emperor master suite, '\
'you will be surrounded by luxurious décor and furnishings. An ensuite bathroom completes '\
'the suite, comprising of top quality designed, bath tub, walkin shower and all amenities '\
'for your convenience . Our king master suite, with cable TV and lakeview is perfect for '\
'relaxing after a busy day at the local attractions! A spacious bathroom featuring twin '\
'basins, roman tub and a large walk in shower awaits your relaxation pleasures! <br><br>'\
'Your vacation starts at the entrance with a 60 ft water feature and tropical boulevard, '\
'towering monuments and reflecting lakes, sculptured sea life sending forth plumes of water. '\
'The home itself has over 3000 sq. feet of living and playing space. <br><br>The Harbour '\
'Lakes Clubhouse is the vibrant center of activity for the community, offering volley ball, '\
'a pool, a children\'s play area, tennis, hiking and biking trails, a fitness facility and '\
'spa with hot tub, sauna, and steam room GAME ROOM HOME WIRELESS HIGH SPEED INTERNET ACCESS '\
'<br><br>If it’s relaxed living and plush surroundings you’re looking for, then this villa '\
'has it all A warm welcome to our luxurious home where we hope that you will enjoy the '\
'perfect vacation! Our open plan villa was designed with your relaxation in mind. <br><br>'\
'Located in the Reunion Resort, this beautiful home backs onto a conservation area. Reunion'\
' is probably the most prestigious rental community in Central Florida having every amenity'\
' that you could want to make yours a memorable vacation from restaurants, bars, swimming '\
'pools, 3 PGA golf courses, spa and water park though membership is required for certain '\
'amenities. The resort is also ideally situated for all the major parks, Disney, Universal '\
'&amp; Seaworld with many local attractions situated on the US192 a ten minute drive away. '\
'The main entrance is only two minutes from I4 giving easy access to both the Gulf and '\
'Atlantic coast lines for great beaches.'

      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to eq expected
    end
  end
end