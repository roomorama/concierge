require 'spec_helper'

RSpec.describe JTB::Price do
  include Support::JTBClientHelper

  let(:credentials) { double(id: 'some id', user: 'Roberto', password: '123', company: 'Apple') }

  subject { described_class.new(credentials) }

  describe '#quote' do
    context 'success' do


      it 'returns quotation with optimal price' do
        result = subject.quote(success_response)
        expect(result).to be_a Result
        expect(result).to be_success

        expect(result.value).to be_a Quotation
        expect(result.value).to be subject.quotation


        quotation = result.value
        expect(quotation).to be_successful
        expect(quotation.total).to eq 4100
        expect(quotation.available).to be true
      end
    end

    context 'fail' do
      let(:fail_response) {
        { ga_hotel_avail_rs: { error: 'Some error' } }
      }

      it 'returns quotation' do
        result = subject.quote(fail_response)
        expect(result).to be_a Result
        expect(result).not_to be_success
        expect(result.error.code).to eq :unavailable_property
      end

    end
  end

end