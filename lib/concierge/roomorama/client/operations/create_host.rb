class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::CreateHost+
  #
  # This class is responsible for encapsulating the operation of creating host
  # using Roomorama's API.
  #
  # The /create-host api behaves like "update or insert"
  #
  # Usage
  #
  #   operation = Roomorama::Client::Operations::CreateHost.new
  #   roomorama_client.perform(operation)
  class CreateHost

    # the Roomorama API endpoint for the +create-host+ call
    ENDPOINT = '/v1.0/create-host'

    attr_reader :supplier, :username, :name, :email, :phone, :payment_terms

    def initialize(supplier, username, name, email, phone, payment_terms)
      @supplier      = supplier
      @name          = name
      @username      = username
      @email         = email
      @phone         = phone
      @payment_terms = payment_terms
    end

    def endpoint
      ENDPOINT
    end

    def request_method
      :post
    end

    def request_data
      {
        "supplier": supplier.name,
        "host": {
          "username":      username,
          "name":          name,
          "email":         email,
          "phone":         phone,
          "payment_terms": payment_terms
        },
        "webhooks": {
          "quote": {
            "production": "#{webhook_host}/#{supplier_path}/quote",
            "test":       "#{test_webhook_host}/#{supplier_path}/quote"
          },
          "checkout": {
            "production": "#{webhook_host}/#{supplier_path}/checkout"
          },
          "booking": {
            "production": "#{webhook_host}/#{supplier_path}/booking",
            "test":       "#{test_webhook_host}/#{supplier_path}/booking"
          },
          "cancellation": {
            "production": "#{webhook_host}/#{supplier_path}/cancel",
            "test":       "#{test_webhook_host}/#{supplier_path}/cancel"
          }
        }
      }
    end

    def webhook_host
      resolve_api_url!(ENV["ROOMORAMA_API_ENVIRONMENT"])
    end

    def test_webhook_host
      resolve_api_url!(:staging)
    end

    def supplier_path
      Concierge::SupplierRoutes.sub_path(supplier.name)
    end

    private

    def resolve_api_url!(environment)
      {
        production: "https://concierge.roomorama.com",
        sandbox:    "https://concierge-sandbox.roomorama.com",
        staging:    "https://concierge-staging.roomorama.com",
        staging2:   "https://concierge-staging2.roomorama.com",
        staging3:   "https://concierge-staging3.roomorama.com"
      }[environment.to_s.to_sym].tap do |url|
        raise Roomorama::Client::UnknownEnvironmentError.new(environment) unless url
      end
    end
  end
end

