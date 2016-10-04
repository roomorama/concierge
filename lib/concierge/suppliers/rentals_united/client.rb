module RentalsUnited
  # +RentalsUnited::Client+
  class Client
    SUPPLIER_NAME = "RentalsUnited"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Cancels a reservation by given reference_number
    #
    # Usage
    #
    #   client = RentalsUnited::Client.new(credentials)
    #   result = client.cancel(params)
    #
    # Returns a +Result+ wrapping a +String+ with reference_number number when
    # operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def cancel(params)
      command = RentalsUnited::Commands::Cancel.new(
        credentials,
        params[:reference_number]
      )
      command.call
    end
  end
end
