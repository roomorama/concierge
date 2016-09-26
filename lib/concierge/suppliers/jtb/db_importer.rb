module JTB
  class DBImporter

    # Units (RoomType_All_YYYYMMDD.csv)
    ROOM_TYPE_COLUMNS = [
      0,  # language
      1,  # city_code
      2,  # hotel_code
      3,  # room_code
      4,  # room_grade
      5,  # room_type_code
      6,  # room_name
      11, # min_guests
      12, # max_guests
      13, # extra_bed
      14, # extra_bed_type
      15, # size1
      16, # size2
      17, # size3
      18, # size4
      19, # size5
      20  # size6
    ]


    attr_reader :tmp_path

    def initialize(tmp_path)
      @tmp_path = tmp_path
    end

    def import
      import_room_types
    end

    def cleanup
      JTB::Repositories::RoomTypeRepository.clear
    end

    private

    CSV_DELIMETER = "\t"

    def import_room_types
      file_path = room_types_file_path
      if file_path
        File.open(file_path) do |file|
          JTB::Repositories::RoomTypeRepository.copy_csv_into do
            line = file.gets
            fetch_required_columns(line, ROOM_TYPE_COLUMNS) if line
          end
        end
      end
    end

    def fetch_required_columns(line, indexes)
      line.split(CSV_DELIMETER).values_at(*indexes).join(CSV_DELIMETER) + "\n"
    end

    def room_types_file_path
      local_file_path('RoomType_ALL')
    end

    def local_file_path(prefix)
      Dir.glob(File.join(tmp_path, "#{prefix}*.csv")).first
    end
  end
end