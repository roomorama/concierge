class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::CreateHost+
  #
  # This class is responsible for encapsulating the operation of creating host
  # using Roomorama's API.
  #
  # Usage
  #
  #   operation = Roomorama::Client::Operations::CreateHost.new
  #   roomorama_client.perform(operation)
  class CreateHost

    # the Roomorama API endpoint for the +create-host+ call
    ENDPOINT = '/v1.0/create-host'

    attr_reader :supplier, :username, :name, :email, :phone

    def initialize(supplier, username, name, email, phone)
      @supplier = supplier
      @name     = name
      @username = username
      @email    = email
      @phone    = phone
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
          "username": username,
          "name":     name,
          "email":    email
        },
        "webhooks": {
          "quote": {
            "production": "https://concierge.roomorama.com/#{supplier_path}/quote",
            "test":       "https://concierge-staging.roomorama.com/#{supplier_path}/quote"
          },
          "checkout": {
            "production": "https://concierge.roomorama.com/#{supplier_path}/checkout"
          },
          "booking": {
            "production": "https://concierge.roomorama.com/#{supplier_path}/booking",
            "test": "https://concierge-staging.roomorama.com/#{supplier_path}/booking"
          },
          "cancellation": {
            "production": "https://concierge.roomorama.com/#{supplier_path}/cancel",
            "test":       "https://concierge-staging.roomorama.com/#{supplier_path}/cancel"
          }
        }
      }
    end

    def supplier_path
      Concierge::SupplierRoutes.sub_path(supplier.name)
    end
  end
end

