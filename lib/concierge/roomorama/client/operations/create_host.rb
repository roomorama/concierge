class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::CreateHost+
  # Creates a host using the create-host endpoint.
  #
  class CreateHost

    # the Roomorama API endpoint for the +create-host+ call
    ENDPOINT = "/v1.0/create-host"
    WEBHOOK_HOST_PRODUCTION = "concierge.roomorama.com"
    WEBHOOK_HOST_STAGING = "concierge-staging.roomorama.com"

    attr_reader :identifiers

    # Args:
    #   identifier - host id on partner's system
    #   username   - username to be on roomorama's system
    #   supplier   - the related supplier partner
    #
    def initialize(name:, email:, username:, phone:, supplier_name:)
      @name          = name
      @email         = email
      @username      = username
      @phone         = phone
      @supplier_name = supplier_name
    end

    def endpoint
      ENDPOINT
    end

    def request_method
      :post
    end

    def request_data
      {
        supplier: @supplier_name ,
        host: {
          name: @name,
          username: @username,
          email: @email,
          phone: @phone,
        },
        webhooks: {
          quote: {
            production: "https://#{WEBHOOK_HOST_PRODUCTION}/#{supplier_namespace}/quote",
            test: "https://#{WEBHOOK_HOST_STAGING}/#{supplier_namespace}/quote",
          },
          booking: {
            production: "https://#{WEBHOOK_HOST_PRODUCTION}/#{supplier_namespace}/booking",
            test: "https://#{WEBHOOK_HOST_STAGING}/#{supplier_namespace}/booking",
          },
          cancellation: {
            production: "https://#{WEBHOOK_HOST_PRODUCTION}/#{supplier_namespace}/cancel",
            test: "https://#{WEBHOOK_HOST_STAGING}/#{supplier_namespace}/cancel",
          }
        }
      }
    end

    private

    def supplier_namespace
      @supplier_name.downcase.gsub("_", "")
    end

  end
end
