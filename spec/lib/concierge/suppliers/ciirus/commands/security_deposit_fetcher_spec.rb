require 'spec_helper'

RSpec.describe Ciirus::Commands::SecurityDepositFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://example.org')
  end

  let(:property_id) { {property_id: '33692'} }

  let(:success_response) { read_fixture('ciirus/responses/extras_response.xml') }
  let(:one_extra_response) { read_fixture('ciirus/responses/one_extra_response.xml') }
  let(:empty_response) { read_fixture('ciirus/responses/extras_response_without_sd.xml') }
  let(:error_response) { read_fixture('ciirus/responses/error_extras_response.xml') }
  let(:wsdl) { read_fixture('ciirus/additional_wsdl.xml') }

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

    context 'when xml response is correct' do
      it 'returns success security deposit extra' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(property_id)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Ciirus::Entities::Extra
      end

      it 'fills extra with right attributes' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(property_id)

        extra = result.value
        expect(extra.property_id).to eq('33692')
        expect(extra.item_code).to eq('SD')
        expect(extra.item_description).to eq('Security Deposit')
        expect(extra.flat_fee).to be_truthy
        expect(extra.flat_fee_amount).to eq(2500.0)
        expect(extra.daily_fee).to be_falsey
        expect(extra.daily_fee_amount).to eq(0)
        expect(extra.percentage_fee).to be_falsey
        expect(extra.percentage).to eq(0)
        expect(extra.mandatory).to be_falsey
        expect(extra.minimum_charge).to eq(0)
      end

      it 'works fine with one extra as well' do
        stub_call(method: described_class::OPERATION_NAME, response: one_extra_response)

        result = subject.call(property_id)

        extra = result.value
        expect(extra.property_id).to eq('33692')
        expect(extra.item_code).to eq('SD')
        expect(extra.item_description).to eq('Security Deposit')
        expect(extra.flat_fee).to be_truthy
        expect(extra.flat_fee_amount).to eq(2500.0)
        expect(extra.daily_fee).to be_falsey
        expect(extra.daily_fee_amount).to eq(0)
        expect(extra.percentage_fee).to be_falsey
        expect(extra.percentage).to eq(0)
        expect(extra.mandatory).to be_falsey
        expect(extra.minimum_charge).to eq(0)
      end
    end

    context('when xml is correct but does not contains sd') do
      it 'returns nil' do
        stub_call(method: described_class::OPERATION_NAME, response: empty_response)

        result = subject.call(property_id)

        expect(result.value).to be_nil
      end
    end

    context 'when xml contains error message' do
      it 'returns a result with error' do
        stub_call(method: described_class::OPERATION_NAME, response: error_response)

        result = subject.call(property_id)

        expect(result.success?).to be false
        expect(result.error.code).to eq :not_empty_error_msg
        expect(result.error.data).to eq("GetExtras: You do not have access rights to this Property (2).")
      end
    end
  end
end

