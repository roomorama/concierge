require "spec_helper"

RSpec.describe Roomorama::Client::Operations::CreateHost do
  subject { described_class.new(name: "1234",
                                username: "1234",
                                email: "ciirus@roomorama.com",
                                phone: "+6598765432",
                                supplier_name: "Ciirus"
                               ) }

  describe "#endpoint" do
    it "knows the endpoint where a host can be created" do
      expect(subject.endpoint).to eq "/v1.0/create-host"
    end
  end

  describe "#method" do
    it "knows the request method to be used when publishing" do
      expect(subject.request_method).to eq :post
    end
  end

  describe "#request_data" do
    it "includes host and webhooks info" do
      expected_paylaod = {
        supplier: "Ciirus" ,
        host: {
          name: "1234",
          username: "1234",
          email: "ciirus@roomorama.com",
          phone: "+6598765432",
        },
        webhooks: {
          quote: {
            production: "https://concierge.roomorama.com/ciirus/quote",
            test: "https://concierge-staging.roomorama.com/ciirus/quote",
          },
          booking: {
            production: "https://concierge.roomorama.com/ciirus/booking",
            test: "https://concierge-staging.roomorama.com/ciirus/booking",
          },
          cancellation: {
            production: "https://concierge.roomorama.com/ciirus/cancel",
            test: "https://concierge-staging.roomorama.com/ciirus/cancel",
          }
        }
      }
      expect(subject.request_data).to eq expected_paylaod
    end
  end
end
