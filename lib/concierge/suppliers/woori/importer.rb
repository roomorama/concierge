module Woori
  # +Woori::Importer+
  #
  # This class provides an interface for the bulk import of Woori properties.
  #
  # Usage
  #
  #   importer = Woori::Importer.new(credentials)
  #   importer.fetch_properties(updated_at, limit, offset)
  #   importer.fetch_units("w_w0104006")
  #   importer.fetch_unit_rates("w_w0104006_R01")
  class Importer
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Retrieves the list of properties by given options
    #
    # Arguments:
    #
    #   * +updated_at+ [String] date to start fetching properties from
    #   * +limit+ [Integer] max number of returned properties (batch size)
    #   * +offset+ [Integer] skip first +offset+ properties
    #
    # Usage:
    #
    #   importer.fetch_properties("1970-01-01", 50, 0)
    #
    # Returns a +Result+ wrapping an +Array+ of +Roomorama::Property+ objects
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_properties(updated_at, limit, offset)
      properties_fetcher = Commands::PropertiesFetcher.new(credentials)
      properties_fetcher.call(updated_at, limit, offset)
    end

    # Retrieves the list of units for property by its id
    #
    # Arguments:
    #
    #   * +property_id+ [String] property id (property hash in Woori API)
    #
    # Usage:
    #
    #   importer.fetch_units("w_w0104006")
    #
    # Returns a +Result+ wrapping an +Array+ of +Roomorama::Unit+ objects
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_units(property_id)
      units_fetcher = Commands::UnitsFetcher.new(credentials)
      units_fetcher.call(property_id)
    end

    # Retrieves rates for unit by unit_id
    #
    # Arguments:
    #
    #   * +unit_id+ [String] unit id (room code hash in Woori API)
    #
    # Usage:
    #
    #   importer.fetch_unit_rates("w_w0104006_R01")
    #
    # Returns a +Result+ wrapping +Entities::UnitRates+ object
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_unit_rates(unit_id)
      unit_rates_fetcher = Commands::UnitRatesFetcher.new(credentials)
      unit_rates_fetcher.call(unit_id)
    end
  end
end
