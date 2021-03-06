require "spec_helper"

RSpec.describe THH::Client do
  let(:params) {
    { property_id: '15', check_in: '2016-12-09', check_out: '2016-12-17', guests: 2 }
  }
  let(:credentials) { double(key: 'Foo', url: 'http://example.org') }

  subject { described_class.new(credentials) }

  describe '#quote' do
    it 'returns the wrapped quotation when successful' do
      successful_quotation = Quotation.new(total: 999)
      allow_any_instance_of(THH::Price).to receive(:quote) { Result.new(successful_quotation) }

      quote_result = subject.quote(params)
      expect(quote_result).to be_success

      quote = quote_result.value
      expect(quote).to be_a Quotation
      expect(quote.total).to eq 999
    end

    it 'returns a quotation object with a generic error message on failure' do
      failed_operation = Result.error(:something_failed, 'error message')
      allow_any_instance_of(THH::Price).to receive(:quote) { failed_operation }

      quote_result = subject.quote(params)
      expect(quote_result).to_not be_success
      expect(quote_result.error.code).to eq :something_failed
      expect(quote_result.error.data).to eq 'error message'

      quote = quote_result.value
      expect(quote).to be_nil
    end
  end

  describe '#book' do
    it 'returns the wrapped reservation when successful' do
      successful_reservation = Reservation.new(reference_number: '654987')
      allow_any_instance_of(THH::Booking).to receive(:book) { Result.new(successful_reservation) }

      book_result = subject.book(params)
      expect(book_result).to be_success

      reservation = book_result.value
      expect(reservation).to be_a Reservation
      expect(reservation.reference_number).to eq '654987'
    end

    it 'returns a reservation object with a generic error message on failure' do
      failed_operation = Result.error(:something_failed)
      allow_any_instance_of(THH::Booking).to receive(:book) { failed_operation }

      book_result = subject.book(params)
      expect(book_result).to_not be_success
      expect(book_result.error.code).to eq :something_failed

      reservation = book_result.value
      expect(reservation).to be_nil
    end
  end

  describe '#cancel' do
    let(:params) { { reference_number: '123' } }

    it 'calls cancel command class' do
      expect_any_instance_of(THH::Commands::Cancel).to(receive(:call).with('123'))
      subject.cancel(params)
    end
  end
end
