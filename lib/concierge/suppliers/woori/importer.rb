module Woori
  # +Woori::Importer+
  #
  # This class provides an interface for the bulk import of Woori properties.
  #
  # Usage
  #
  #   importer = Woori::Importer.new(credentials)
  #   importer.fetch_properties
  class Importer
    BATCH_SIZE = 50

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def stream_properties(updated_at:)
      limit = BATCH_SIZE
      offset = 0

      if block_given?
        begin
          result = fetch_properties(updated_at, limit, offset)

          if result.success?
            puts "Fetched: #{result.value.size} (limit: #{limit}, offset: #{offset})"
            size_fetched = result.value.size
            offset = offset + size_fetched

            yield result.value
          else
            return result
          end
        end while size_fetched == limit
        
        Result.new(offset)
      else
        nil
      end
    end

    def fetch_all_properties(updated_at:)
    end

    def fetch_properties(updated_at, limit, offset)
      properties_fetcher = Commands::PropertiesFetcher.new(credentials)
      properties_fetcher.call(updated_at, limit, offset)
    end
  end
end
