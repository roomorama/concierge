require 'spec_helper'

RSpec.describe JTB::Client do

  let(:credentials) {
    { id: 'some id', user: 'Roberto', password: '123', company: 'Apple' }
  }
  let(:params) {
    { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2, unit_id: 'JPN' }
  }

  subject { described_class.new(credentials) }

  describe '#quote' do
    it 'returns the wrapped quotation from JTB::Price when successful' do
      successful_quotation = Quotation.new(total: 999)
      allow_any_instance_of(JTB::Price).to receive(:quote) { Result.new(successful_quotation) }

      quote = subject.quote(params)
      expect(quote).to be_a Quotation
      expect(quote.total).to eq 999
    end

    it 'returns a quotation object with a generic error message on failure' do
      failed_operation = Result.error(:something_failed, "Error")
      allow_any_instance_of(JTB::Price).to receive(:quote) { failed_operation }

      quote = subject.quote(params)
      expect(quote).to be_a Quotation
      expect(quote).not_to be_successful
      expect(quote.errors).to eq({ quote: "Could not quote price with remote supplier" })
    end

  end
end