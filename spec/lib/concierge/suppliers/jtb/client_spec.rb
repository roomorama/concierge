require 'spec_helper'

RSpec.describe JTB::Client do

  let(:credentials) { double(id: 'some id', user: 'Roberto', password: '123', company: 'Apple', url: 'https://trial-www.jtbgenesis.com/genesis2-demo/services') }

  subject { described_class.new(credentials) }

  describe '#quote' do
    let(:params) { wrapper.new(property_id: 10,
                               check_in: Date.today + 10,
                               check_out: Date.today + 20,
                               guests: 2,
                               unit_id: 'JPN')
    }

    it 'returns the result wrapping quotation from JTB::Price when successful' do
      successful_quotation = Quotation.new(total: 999)
      allow_any_instance_of(JTB::Price).to receive(:quote) { Result.new(successful_quotation) }

      quote = subject.quote(params)
      expect(quote).to be_success
      expect(quote.value).to be_a Quotation
      expect(quote.value.total).to eq 999
    end

    it 'returns a result object on failure' do
      failed_operation = Result.error(:something_failed)
      allow_any_instance_of(JTB::Price).to receive(:quote) { failed_operation }

      quote = subject.quote(params)
      expect(quote).to be_a Result
      expect(quote).not_to be_success
      expect(quote.error.data).to be_nil
    end

    context 'exceeded stay length' do
      let(:params) { wrapper.new(property_id: 10,
                                 check_in: Date.today + 10,
                                 check_out: Date.today + 30,
                                 guests: 2,
                                 unit_id: 'JPN')
      }


      it 'returns a error result object with a specific error message in data' do
        quote = subject.quote(params)
        expect(quote).to be_a Result
        expect(quote).not_to be_success
        expect(quote.error.data).to eq({ quote: "Maximum length of stay must be less than 15 nights." })
      end
    end
  end

  describe '#book' do
    let(:params) {
      {
        property_id: 'A123',
        unit_id:     'JPN',
        check_in:    '2016-03-22',
        check_out:   '2016-03-24',
        guests:      2,
        customer:    {
          first_name: 'Alex',
          last_name:  'Black',
          gender:     'male'
        }
      }
    }

    it 'creates record with booking code in database' do
      allow_any_instance_of(JTB::Booking).to receive(:book) { Result.new('booking code') }
      reservation_result = subject.book(params)
      expect(reservation_result).to be_success
      expect(reservation_result.value).to be_a Reservation
      expect(reservation_result.value.code).to eq "booking code"

      expect(ReservationRepository.first.code).to eq 'booking code'
    end

    it "does not stop the booking in case database access is compromised" do
      allow_any_instance_of(JTB::Booking).to receive(:book) { Result.new('booking code') }
      allow(ReservationRepository).to receive(:create) { raise Hanami::Model::UniqueConstraintViolationError }

      expect {
        subject.book(params)
      }.not_to raise_error
    end

  end

  private

  def wrapper
    API::Controllers::Params::Quote
  end
end
