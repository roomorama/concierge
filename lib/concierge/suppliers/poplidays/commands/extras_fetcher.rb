module Poplidays
  module Commands
    # +Poplidays::Commands::LodgingsFetcher+
    #
    # This class is responsible for wrapping the logic related to getting
    # lodging's extras (END_OF_STAY_CLEANING, CLEANING_DURING_THE_STAY, etc) from Poplidays,
    # parsing the response, and building the +Result+ object with the raw data returned from their API.
    #
    # Usage
    #
    #   command = Poplidays::Commands::ExtrasFetcher.new(credentials)
    #   result = command.call(lodging_id)
    #
    #   if result.success?
    #     result.value # Array of hashes
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the array of +Hash+.
    class ExtrasFetcher < BaseCommand

      PATH = 'lodgings/%<id>s/extras'

      def call(lodging_id)
        raw_extras = remote_call(url_params: {id: lodging_id})
        if raw_extras.success?
          json_decode(raw_extras.value)
        else
          raw_extras
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

      def protocol
        'https'
      end
    end
  end
end