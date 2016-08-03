module Woori
  # +Woori::Importer+
  #
  # This class provides an interface for the bulk import of Woori properties
  # from .json files
  class FileImporter
    def fetch_all_properties
      repository = Repositories::File::Properties.new(properties_file)
      repository.all
    end

    def fetch_all_units
      repository = Repositories::File::Units.new(unit_files)
      repository.all
    end

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
