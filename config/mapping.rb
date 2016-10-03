collection :external_errors do
  entity     ExternalError
  repository ExternalErrorRepository

  attribute :id,          Integer
  attribute :operation,   String
  attribute :supplier,    String
  attribute :code,        String
  attribute :description, String
  attribute :context,     Concierge::PGJSON
  attribute :happened_at, Time
end

collection :cache_entries do
  entity     Concierge::Cache::Entry
  repository Concierge::Cache::EntryRepository

  attribute :id,         Integer
  attribute :key,        String
  attribute :value,      String
  attribute :updated_at, Time
end

collection :reservations do
  entity     Reservation
  repository ReservationRepository

  attribute :id,               Integer
  attribute :supplier,         String
  attribute :property_id,      String
  attribute :unit_id,          String
  attribute :check_in,         String
  attribute :check_out,        String
  attribute :guests,           Integer
  attribute :reference_number, String
  attribute :created_at,       Time
  attribute :updated_at,       Time
end

collection :suppliers do
  entity     Supplier
  repository SupplierRepository

  attribute :id,         Integer
  attribute :name,       String
  attribute :created_at, Time
  attribute :updated_at, Time
end

collection :hosts do
  entity     Host
  repository HostRepository

  attribute :id,             Integer
  attribute :supplier_id,    Integer
  attribute :identifier,     String
  attribute :username,       String
  attribute :access_token,   String
  attribute :fee_percentage, Float
  attribute :created_at,     Time
  attribute :updated_at,     Time
end

collection :properties do
  entity     Property
  repository PropertyRepository

  attribute :id,         Integer
  attribute :identifier, String
  attribute :host_id,    Integer
  attribute :data,       Concierge::PGJSON
  attribute :created_at, Time
  attribute :updated_at, Time
end

collection :sync_processes do
  entity     SyncProcess
  repository SyncProcessRepository

  attribute :id,          Integer
  attribute :host_id,     Integer
  attribute :started_at,  Time
  attribute :finished_at, Time
  attribute :successful,  Boolean
  attribute :stats,       Concierge::PGJSON
  attribute :type,        String
  attribute :created_at,  Time
  attribute :updated_at,  Time
end

collection :background_workers do
  entity     BackgroundWorker
  repository BackgroundWorkerRepository

  attribute :id,            Integer
  attribute :host_id,       Integer
  attribute :supplier_id,   Integer
  attribute :next_run_at,   Time
  attribute :next_run_args, Concierge::PGJSON
  attribute :interval,      Integer
  attribute :type,          String
  attribute :status,        String
  attribute :created_at,    Time
  attribute :updated_at,    Time
end

# JTB mapping

collection :jtb_room_types do
  entity     JTB::Entities::RoomType
  repository JTB::Repositories::RoomTypeRepository

  attribute :language,       String
  attribute :city_code,      String
  attribute :hotel_code,     String
  attribute :room_code,      String
  attribute :room_grade,     String
  attribute :room_type_code, String
  attribute :room_name,      String
  attribute :min_guests,     Integer
  attribute :max_guests,     Integer
  attribute :extra_bed,      String
  attribute :extra_bed_type, String
  attribute :size1,          String
  attribute :size2,          String
  attribute :size3,          String
  attribute :size4,          String
  attribute :size5,          String
  attribute :size6,          String
end

collection :jtb_room_stocks do
  entity     JTB::Entities::RoomStock
  repository JTB::Repositories::RoomStockRepository

  attribute :city_code,                String
  attribute :hotel_code,               String
  attribute :rate_plan_id,             String
  attribute :service_date,             String
  attribute :number_of_units,          Integer
  attribute :closing_date,             String
  attribute :sale_status,              String
  attribute :reservation_closing_date, String
end

collection :jtb_hotels do
  entity     JTB::Entities::Hotel
  repository JTB::Repositories::HotelRepository

  attribute :language,             String
  attribute :city_code,            String
  attribute :hotel_code,           String
  attribute :jtb_hotel_code,       String
  attribute :hotel_name,           String
  attribute :location_code,        String
  attribute :hotel_description,    String
  attribute :latitude,             String
  attribute :longitude,            String
  attribute :hotel_type,           String
  attribute :address,              String
  attribute :non_smoking_room,     String
  attribute :parking,              String
  attribute :internet,             String
  attribute :wifi,                 String
  attribute :indoor_pool_free,     String
  attribute :indoor_pool_charged,  String
  attribute :outdoor_pool_free,    String
  attribute :outdoor_pool_charged, String
  attribute :indoor_gym_free,      String
  attribute :indoor_gym_charged,   String
  attribute :outdoor_gym_free,     String
  attribute :outdoor_gym_charged,  String
  attribute :wheelchair_access,    String
end

collection :jtb_pictures do
  entity     JTB::Entities::Picture
  repository JTB::Repositories::PictureRepository

  attribute :language,   String
  attribute :city_code,  String
  attribute :hotel_code, String
  attribute :sequence,   Integer
  attribute :category,   String
  attribute :room_code,  String
  attribute :url,        String
  attribute :comments,   String
end

collection :jtb_lookups do
  entity     JTB::Entities::Lookup
  repository JTB::Repositories::LookupRepository

  attribute :language,   String
  attribute :category,   String
  attribute :id,         String
  attribute :related_id, String
  attribute :name,       String
end

collection :jtb_rate_plans do
  entity     JTB::Entities::RatePlan
  repository JTB::Repositories::RatePlanRepository

  attribute :city_code,      String
  attribute :hotel_code,     String
  attribute :rate_plan_id,   String
  attribute :room_code,      String
  attribute :meal_plan_code, String
  attribute :occupancy,      String
end

collection :jtb_room_prices do
  entity     JTB::Entities::RoomPrice
  repository JTB::Repositories::RoomPriceRepository

  attribute :city_code,    String
  attribute :hotel_code,   String
  attribute :rate_plan_id, String
  attribute :date,         Date
  attribute :room_rate,    Float
end