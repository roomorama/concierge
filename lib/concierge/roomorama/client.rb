require_relative "error"

module Roomorama

  # +Roomorama::Client+
  #
  # This is a thin Roomorama client. Currently, it is supposed to support only
  # Roomorama's +publish+ API - that is, the +publish+ and +diff+ set of endpoints.
  #
  # This class, however, has no knowledge of such operations, and is able to perform
  # any +operation+. An operation is an object that responds to the following methods:
  #
  # * request_method - the HTTP request method to be performed.
  # * endpoint       - the API endpoint, a relative path to the root Roomorama API
  # * request_data   - the request data, if any, for the API call.
  #
  # Therefore, given an operation, this client is able to use the credentials given
  # on initialization to perform arbitrary API calls.
  #
  # Usage
  #
  #   operation = Roomorama::Client::Operations.publish(property)
  #   client = Roomorama::Client.new(access_token)
  #   client.perform(operation) # => Result<...>
  class Client

    # +Roomorama::Client::UnknownEnvironmentError+
    #
    # This error is raised when an unknown API environment is specified when
    # initialising the client.
    class UnknownEnvironmentError < Roomorama::Error
      def initialize(environment)
        accepted = Roomorama::Client::ENVIRONMENTS
        super %(Unknown Roomorama API environment "#{environment}". Accepted environments are: #{accepted})
      end
    end

    include Concierge::JSON

    ENVIRONMENTS = %i(production sandbox staging)

    attr_reader :access_token, :api_url

    def initialize(access_token, environment: :production)
      @access_token = access_token
      @api_url      = resolve_api_url!(environment)
    end

    def perform(operation)
      http.public_send(
        operation.request_method,
        operation.endpoint,
        json_encode(operation.request_data),
        headers
      )
    end

    private

    def http
      @http ||= Concierge::HTTPClient.new(api_url)
    end

    def headers
      {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type"  => "application/json"
      }
    end

    def resolve_api_url!(environment)
      {
        production: "https://api.roomorama.com",
        sandbox:    "https://api.sandbox.roomorama.com",
        staging:    "https://api.staging.roomorama.com"
      }[environment.to_s.to_sym].tap do |url|
        raise UnknownEnvironmentError.new(environment) unless url
      end
    end

  end

end
