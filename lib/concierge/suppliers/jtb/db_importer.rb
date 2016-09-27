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

    # Availabilities (RoomStock_All_YYYMMDD.csv)
    ROOM_STOCK_COLUMNS = [
      0, # language
      1, # hotel_code
      2, # option_plan_id
      3, # service_date
      4, # number_of_units
      5, # closing_date
      6, # sale_status
      7  # reservation_closing_date
    ]

    # Rooms (HotelInfo_All_YYYYMMDD.csv)
    HOTEL_INFO_COLUMNS = [
      0,   # language
      1,   # city_code
      2,   # hotel_code
      3,   # jtb_hotel_code
      6,   # hotel_name
      9,   # location_code
      10,  # hotel_description
      19,  # latitude
      20,  # longitude
      22,  # hotel_type
      24,  # address
      37,  # non_smoking_room
      71,  # parking
      108, # internet
      112, # wifi
      123, # indoor_pool_free
      130, # indoor_pool_charged
      137, # outdoor_pool_free
      144, # outdoor_pool_charged
      128, # indoor_gym_free
      135, # indoor_gym_charged
      142, # outdoor_gym_free
      149, # outdoor_gym_charged
      165  # wheelchair_access
    ]

    # Images (PictureMaster_ALL_YYYYMMDD.csv)
    PICTURE_FILE_COLUMNS = [
      0, # language
      1, # city_code
      2, # hotel_code
      3, # sequence
      4, # category
      5, # room_code
      7, # url
      8  # comments
    ]

    attr_reader :tmp_path

    def initialize(tmp_path)
      @tmp_path = tmp_path
    end

    def import
      # import_room_types
      # import_room_stocks
      # import_hotels
      import_pictures
    end

    def cleanup
      JTB::Repositories::RoomTypeRepository.clear
      JTB::Repositories::RoomStockRepository.clear
      JTB::Repositories::HotelRepository.clear
      JTB::Repositories::PictureRepository.clear
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

    def import_room_stocks
      file_path = room_stocks_file_path
      if file_path
        File.open(file_path) do |file|
          JTB::Repositories::RoomStockRepository.copy_csv_into do
            line = file.gets
            fetch_required_columns(line, ROOM_STOCK_COLUMNS) if line
          end
        end
      end
    end

    def import_hotels
      file_path = hotels_file_path
      if file_path
        File.open(file_path) do |file|
          JTB::Repositories::HotelRepository.copy_csv_into do
            line = file.gets
            fetch_required_columns(line, HOTEL_INFO_COLUMNS) if line
          end
        end
      end
    end

    def import_pictures
      file_path = pictures_file_path
      if file_path
        File.open(file_path) do |file|
          JTB::Repositories::PictureRepository.copy_csv_into do
            line = file.gets
            fetch_required_columns(line, PICTURE_FILE_COLUMNS) if line
          end
        end
      end
    end

    def fetch_required_columns(line, indexes)
      # Remove last \n from string
      line = line[0..-2]
      line.split(CSV_DELIMETER).values_at(*indexes).join(CSV_DELIMETER) + "\n"
    end

    def room_types_file_path
      local_file_path('RoomType_ALL')
    end

    def room_stocks_file_path
      local_file_path('RoomStock_ALL')
    end

    def hotels_file_path
      local_file_path('HotelInfo_ALL')
    end

    def pictures_file_path
      local_file_path('PictureMaster_ALL')
    end

    def local_file_path(prefix)
      Dir.glob(File.join(tmp_path, "#{prefix}*.csv")).first
    end
  end
end