class Roomorama::Client::Operations

  # +Roomorama::Client::Operations::DisableHost+
  #
  # This class is responsible for encapsulating the operation of disabling host
  # which was deactivated on Supplier's side, using Roomorama's API.
  #
  # Usage
  #
  #   operation = Roomorama::Client::Operations::DisableHost.new
  #   roomorama_client.perform(operation)
  class DisableHost

    # the Roomorama API endpoint for the +disable-host+ call
    ENDPOINT = '/v1.0/disable-host'

    def endpoint
      ENDPOINT
    end

    def request_method
      :put
    end

    def request_data
    end

  end
end
