module Woori
  # +Woori::FileImporter+
  #
  # This class provides an interface for the bulk import of Woori properties
  # +Woori::FileImporter+ imports data from files (from .json files)
  class FileImporter
    # Retrieves the list of all properties
    #
    # Returns an +Array+ of +Roomorama::Property+ objects
    def fetch_all_properties
      repository = Repositories::File::Properties.new(properties_file)
      repository.all
    end

    # Retrieves the list of all units
    #
    # Returns an +Array+ of +Roomorama::Unit+ objects
    def fetch_all_units
      repository = Repositories::File::Units.new(unit_files)
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
      repository = Repositories::File::Units.new(unit_files)
      repository.find_all_by_property_id(property_id)
    end

    private
    def properties_file
      '/Users/ruslansharipov/Downloads/YTL_bulk_data_160801/bulk_properties.json'
    end

    def unit_files
      [
        '/Users/ruslansharipov/Downloads/YTL_bulk_data_160801/bulk_roomtypes_0_to_10000.json',
        '/Users/ruslansharipov/Downloads/YTL_bulk_data_160801/bulk_roomtypes_10000_to_20000.json',
        '/Users/ruslansharipov/Downloads/YTL_bulk_data_160801/bulk_roomtypes_20000_to_30000.json'
      ]
    end
  end
end
