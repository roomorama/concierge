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
        key = ['availabilities', '.', lodging_id].join

        raw_availabilities = with_cache(key) do
          remote_call(url_params = {id: lodging_id})
        end

        if raw_availabilities.success?
          json_decode(raw_availabilities.value)
        else
          raw_availabilities
        end
      end

      protected

      def path
        PATH
      end

      def authentication_required?
        false
      end

      def method
        :get
      end
    end
  end
end