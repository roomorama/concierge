module Woori
  # +Woori::Importer+
  #
  # This class provides an interface for the bulk import of Woori properties
  # +Woori::Importer+ imports data from files (from .json files)
  class Importer
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Get type of import files ("local-files" or "remote-files")
    def import_type
      credentials.import_files_type
    end

    # Retrieves the list of all properties
    #
    # Returns an +Array+ of +Roomorama::Property+ objects
    def fetch_all_properties
      location = credentials.properties_import_file
      file = read_file(import_type, location)

      command = Commands::PropertiesFetcher.new(file)
      command.load_all_properties
    end

    # Retrieves the list of all units
    #
    # Returns an +Array+ of +Roomorama::Unit+ objects
    def fetch_all_units
      locations = [
        credentials.units_1_import_file,
        credentials.units_2_import_file,
        credentials.units_3_import_file
      ]

      files = locations.map { |location| read_file(import_type, location) }

      command = Commands::UnitsFetcher.new(files)
      command.load_all_units
    end

    # Retrieves the list of units for a given property by its id
    #
    # Arguments:
    #
    #   * +property_id+ [String] property id (property hash in Woori API)
    #
    # Returns an +Array+ of +Roomorama::Unit+ objects
    def fetch_all_property_units(property_id)
      locations = [
        credentials.units_1_import_file,
        credentials.units_2_import_file,
        credentials.units_3_import_file
      ]

      files = locations.map { |location| read_file(import_type, location) }

      command = Commands::UnitsFetcher.new(files)
      command.find_all_by_property_id(property_id)
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
      calendar_fetcher = Commands::CalendarFetcher.new(credentials)
      calendar_fetcher.call(property)
    end

    private
    def read_file(type, location)
      case type
      when "local-files"
        File.new(location, 'r')
      when "remote-files"
        URI.parse(location).open
      end
    end
  end
end
