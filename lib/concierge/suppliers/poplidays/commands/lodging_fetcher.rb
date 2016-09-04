module Poplidays
  module Commands
    # +Poplidays::Commands::LodgingFetcher+
    #
    # This class is responsible for wrapping the logic related to getting
    # lodging details from Poplidays, parsing the response,
    # and building the +Result+ object with the raw data returned from their API.
    # Can cache the result, by default cache is turned off
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
      DEFAULT_FRESHNESS = 0 # no cache

      def call(lodging_id, freshness: DEFAULT_FRESHNESS)
        key = ['lodging', lodging_id].join('.')

        raw_lodging = with_cache(key, freshness: freshness) do
          remote_call(url_params: {id: lodging_id})
        end
        if raw_lodging.success?
          result = json_decode(raw_lodging.value)
          return result unless result.success?

          Result.new(Concierge::SafeAccessHash.new(result.value))
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