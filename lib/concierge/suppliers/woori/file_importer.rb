module Woori
  # +Woori::FileImporter+
  #
  # This class provides an interface for the bulk import of Woori properties
  # +Woori::FileImporter+ imports data from files (from .json files)
  class FileImporter
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Retrieves the list of all properties
    #
    # Returns an +Array+ of +Roomorama::Property+ objects
    def fetch_all_properties
      location = credentials.properties_import_file

      repository = Repositories::File::Properties.new(location)
      repository.all
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

      repository = Repositories::File::Units.new(locations)
      repository.all
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

      repository = Repositories::File::Units.new(locations)
      repository.find_all_by_property_id(property_id)
    end
  end
end
