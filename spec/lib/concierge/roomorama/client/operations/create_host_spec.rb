require "spec_helper"

RSpec.describe Roomorama::Client::Operations::CreateHost do

  let(:name) { "Test Guy" }
  let(:email) { "test@guy.com" }
  let(:username) { "test_guy" }
  let(:supplier) { Supplier.new(name: "KigoLegacy") }
  let(:phone) { '123456798' }

  before {
    ENV["ROOMORAMA_API_ENVIRONMENT"] = "production"
  }

  describe "#request_data" do
    it "should return the correct create-host request data" do
      expected_data = {
        "supplier": "KigoLegacy",
        "host": {
          "username": "test_guy",
          "name":     "Test Guy",
          "email":    "test@guy.com"
        },
        "webhooks": {
          "quote": {
            "production": "https://concierge.roomorama.com/kigo/legacy/quote",
            "test":       "https://concierge-staging.roomorama.com/kigo/legacy/quote"
          },
          "checkout": {
            "production": "https://concierge.roomorama.com/kigo/legacy/checkout"
          },
          "booking": {
            "production": "https://concierge.roomorama.com/kigo/legacy/booking",
            "test": "https://concierge-staging.roomorama.com/kigo/legacy/booking"
          },
          "cancellation": {
            "production": "https://concierge.roomorama.com/kigo/legacy/cancel",
            "test":       "https://concierge-staging.roomorama.com/kigo/legacy/cancel"
          }
        }
      }
      operation =  described_class.new(supplier, username, name, email, phone)
      expect(operation.request_data).to eq expected_data

      expected_data = {
        "supplier": "THH",
        "host": {
          "username": "test_guy",
          "name":     "Test Guy",
          "email":    "test@guy.com"
        },
        "webhooks": {
          "quote": {
            "production": "https://concierge.roomorama.com/thh/quote",
            "test":       "https://concierge-staging.roomorama.com/thh/quote"
          },
          "checkout": {
            "production": "https://concierge.roomorama.com/thh/checkout"
          },
          "booking": {
            "production": "https://concierge.roomorama.com/thh/booking",
            "test": "https://concierge-staging.roomorama.com/thh/booking"
          },
          "cancellation": {
            "production": "https://concierge.roomorama.com/thh/cancel",
            "test":       "https://concierge-staging.roomorama.com/thh/cancel"
          }
        }
      }

      supplier = Supplier.new(name: "THH")
      operation =  described_class.new(supplier, username, name, email, phone)
      expect(operation.request_data).to eq expected_data
    end
  end
end

