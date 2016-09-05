module Woori
  # +Woori::Importer+
  #
  # This class provides an interface for the bulk import of Woori properties
  # +Woori::Importer+ imports data from files (from .json files)
  class Importer

    class << self
      # +file_fetcher+ - determines how to fetch property/unit files from Woori.
      #
      # The object assigned to this variable must follow the protocol:
      #
      # +read(location)+
      # Returns a String containing the content of the file in the given +location+
      #
      # Useful to allow filesystem reading when on development/test environments,
      # and to use a S3 URL when on staging/production environments.
      attr_accessor :file_fetcher
    end

    # +Woori::Importer::NoFetcherRegisteredError+
    #
    # Error raised when trying to import Woori properties without previously
    # assigning a +file_fetcher+ attribute.
    class NoFetcherRegisteredError < RuntimeError
      def initialize
        super("No `file_fetcher' attribute set for Woori::Importer")
      end
    end

    attr_reader :credentials, :units_fetcher, :properties_fetcher,
                :calendar_fetcher

    def initialize(credentials)
      @credentials = credentials
      @units_fetcher = Commands::UnitsFetcher.new(units_import_files)
      @properties_fetcher = Commands::PropertiesFetcher.new(properties_import_file)
      @calendar_fetcher = Commands::CalendarFetcher.new(credentials)
    end

    # Retrieves the list of all properties
    #
    # Returns an +Array+ of +Roomorama::Property+ objects
    def fetch_all_properties
      properties_fetcher.load_all_properties
    end

    # Retrieves the list of all units
    #
    # Returns an +Array+ of +Roomorama::Unit+ objects
    def fetch_all_units
      units_fetcher.load_all_units
    end

    # Retrieves the list of units for a given property by its id
    #
    # Arguments:
    #
    #   * +property_id+ [String] property id (property hash in Woori API)
    #
    # Returns an +Array+ of +Roomorama::Unit+ objects
    def fetch_all_property_units(property_id)
      units_fetcher.find_all_by_property_id(property_id)
    end

    # Retrieves availabilities data and builds calendar for property
    # and all its units
    #
    # Arguments:
    #
    #   * +property+ [Property] property to fetch calender for
    #
    # Usage:
    #
    #   importer.fetch_calendar(property)
    #
    # Returns a +Result+ wrapping +Roomorama::Calendar+ object
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_calendar(property)
      calendar_fetcher.call(property)
    end

    private

    def fetcher
      self.class.file_fetcher || (raise NoFetcherRegisteredError)
    end

    def units_import_files
      @units_import_files ||= fetch_unit_import_files
    end

    def properties_import_file
      @properties_import_file ||= fetch_properties_import_file
    end

    def fetch_properties_import_file
      location = credentials.properties_import_file
      fetcher.read(location)
    end

    def fetch_unit_import_files
      locations = [
        credentials.units_1_import_file,
        credentials.units_2_import_file,
        credentials.units_3_import_file
      ]

      locations.map { |location| fetcher.read(location) }
    end
  end
end
