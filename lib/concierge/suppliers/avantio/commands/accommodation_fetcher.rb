module Avantio
  module Commands
    # +Avantio::Commands::AccommodationsFetcher+
    #
    # Base class for all call Ciirus API commands. Each child should
    # implement two methods:
    #  - call(params) - API call execution with returning +Result+
    #  - operation_name - name of API method
    #
    # There are two API endpoints: general and additional, so
    # remote_call and additional_remote_call makes appropriate requests.
    class AccommodationsFetcher
      CODE = 'accommodations'

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def call
        accommodations_raw = fetcher.fetch(CODE)
        return accommodations_raw unless accommodations_raw.success?

        build_accommodations(accommodations_raw.value)
      end

      private

      def fetcher
        @fetcher ||= Avantio::Fetcher.new(credentials.code_partner)
      end

      def mapper
        @mapper ||= Avantio::Mappers::Accommodation.new
      end

      def build_accommodations(accommodations_raw)
        require 'byebug'; byebug

        accommodations = accommodations_raw.xpath('/AccommodationList/AccommodationData')

        Array(accommodations).map { |accommodation| mapper.build(accommodation) }
      end
    end
  end
end