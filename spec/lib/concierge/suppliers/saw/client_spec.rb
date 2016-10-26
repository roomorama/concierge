require 'spec_helper'

RSpec.describe SAW::Client do
  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:client) { described_class.new(credentials) }

  describe "#cancel" do
    let(:params) { { reference_number: '123' } }

    it "calls cancel command class" do
      fetcher_class = SAW::Commands::Cancel

      expect_any_instance_of(fetcher_class).to(receive(:call).with('123'))
      client.cancel(params)
    end
  end

  describe "#book" do
    let(:params) do
      Concierge::SafeAccessHash.new({
        property_id: '1',
        unit_id: '9733',
        check_in: '02/02/2016',
        check_out: '03/02/2016',
        guests: 1,
        currency_code: 'EUR',
        subtotal: '123.45',
        customer: {
          first_name: 'Test',
          last_name: 'User',
          email: 'testuser@example.com',
          display: 'Test User'
        }
      })
    end
    it "sends default customer email" do
      expected_payload = {
        property_id: '1',
        unit_id: '9733',
        check_in: '02/02/2016',
        check_out: '03/02/2016',
        num_guests: 1,
        currency_code: 'EUR',
        total: '123.45',
        user: {
          first_name: 'Test',
          last_name: 'User',
          email: 'saw@bridgerentals.com',
        }
      }
      expect_any_instance_of(SAW::PayloadBuilder).to receive(:build_booking_request)
        .with(expected_payload)
        .and_call_original

      client.book(params)
    end
  end
end
