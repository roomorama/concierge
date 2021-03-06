module Poplidays
  module Commands
    # +Poplidays::Commands::LodgingsFetcher+
    #
    # This class is responsible for wrapping the logic related to getting all
    # lodgings from Poplidays, parsing the response, and building the +Result+ object
    # with the raw data returned from their API.
    #
    # Usage
    #
    #   command = Poplidays::Commands::LodgingsFetcher.new(credentials)
    #   result = command.call
    #
    #   if result.success?
    #     result.value # Array of hashes
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the array of +Hash+.
    class LodgingsFetcher < BaseCommand

      PATH = 'lodgings/out/Roomorama'
      # The response is >75mb it requires a lot of time
      TIMEOUT = 180

      def call
        raw_lodgings = remote_call
        if raw_lodgings.success?
          json_decode(raw_lodgings.value)
        else
          raw_lodgings
        end
      end

      protected

      def path
        PATH
      end

      def authentication
        without_authentication
      end

      def method
        :get
      end

      def protocol
        'http'
      end

      def timeout
        TIMEOUT
      end
    end
  end
end