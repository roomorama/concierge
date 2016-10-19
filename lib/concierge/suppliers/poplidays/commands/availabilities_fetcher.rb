require_relative 'base_command'

module Poplidays
  module Commands
    # +Poplidays::Commands::AvailabilitiesFetcher+
    #
    # This class is responsible for wrapping the logic related to getting all
    # lodging's availabilities from Poplidays, parsing the response,
    # and building the +Result+ object with the raw data returned from their API.
    #
    # Usage
    #
    #   command = Poplidays::Commands::AvailabilitiesFetcher.new(credentials)
    #   result = command.call(property_id)
    #
    #   if result.success?
    #     result.value # Array of hashes
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +Hash+.
    class AvailabilitiesFetcher < BaseCommand

      PATH = 'lodgings/%<id>s/availabilities'

      def call(lodging_id)
        raw_availabilities = remote_call(url_params: {id: lodging_id})

        if raw_availabilities.success?
          result = json_decode(raw_availabilities.value)

          return result unless result.success?

          if result.value.nil?
            Result.error(:unexpected_availabilities_response,
                         'Unexpected response from Poplidays availabilities endpoint')
          end

          Result.new(Concierge::SafeAccessHash.new(result.value))
        else
          raw_availabilities
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