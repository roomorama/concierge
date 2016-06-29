require 'spec_helper'

RSpec.describe Ciirus::Commands::QuoteFetcher do
  include Support::Fixtures

  let(:credentials) { double(username: 'Foo', password: '123') }
  let(:params) do
    API::Controllers::Params::Quote.new(property_id: 38180,
                                        check_in: '2016-05-01',
                                        check_out: '2016-05-12',
                                        guests: 3)
  end

  let(:success_response) { read_fixture('ciirus/property_quote_response.xml') }
  subject { described_class.new(credentials) }

  describe '#call' do

    it 'returns success quotation' do
      allow(subject).to receive(:remote_call) { Result.new(success_response) }

      result = subject.call(params)

      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to be_a Quotation
    end
  end
end