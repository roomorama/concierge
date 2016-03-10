require 'spec_helper'

RSpec.describe JTB::Price do
  include Support::Fixtures
  include Support::JTBClientHelper

  let(:credentials) { double(id: 'some id', user: 'Roberto', password: '123', company: 'Apple', url: 'https://trial-www.jtbgenesis.com/genesis2-demo/services') }
  let(:params) {
    { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2, unit_id: 'JPN' }
  }
  subject { described_class.new(credentials) }

  describe '#quote' do
    context 'success' do
      let(:success_response) { parse_response('jtb/success_quote_response.json') }

      it 'returns quotation with optimal price' do
        allow_any_instance_of(JTB::API).to receive(:quote_price) { Result.new(success_response) }

        result = subject.quote(params)
        expect(result).to be_a Result
        expect(result).to be_success

        expect(result.value).to be_a Quotation
      end
    end

    context 'fail' do
      let(:fail_response) { parse_response('jtb/invalid_request.json') }

      it 'returns quotation' do
        allow_any_instance_of(JTB::API).to receive(:quote_price) { Result.new(fail_response) }

        result = subject.quote(params)
        expect(result).to be_a Result
        expect(result).not_to be_success
      end

    end
  end

  private

  def parse_response(fixture_path)
    Yajl::Parser.parse read_fixture(fixture_path), symbolize_keys: true
  end
end