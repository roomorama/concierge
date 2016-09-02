module Poplidays
  module Commands
    # +Poplidays::Commands::LodgingFetcher+
    #
    # This class is responsible for wrapping the logic related to getting
    # lodging details from Poplidays, parsing the response,
    # and building the +Result+ object with the raw data returned from their API.
    #
    # Usage
    #
    #   command = Poplidays::Commands::LodgingFetcher.new(credentials)
    #   result = command.call(property_id)
    #
    #   if result.success?
    #     result.value # Array of hashes
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the array of +Hash+.
    class LodgingFetcher < BaseCommand

      PATH = 'lodgings/%<id>s'

      def call(lodging_id)
        raw_lodging = remote_call(url_params: {id: lodging_id})
        if raw_lodging.success?
          json_decode(raw_lodging.value)
        else
          raw_lodging
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
    end
  end
end