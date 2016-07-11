collection :external_errors do
  entity     ExternalError
  repository ExternalErrorRepository

  attribute :id,          Integer
  attribute :operation,   String
  attribute :supplier,    String
  attribute :code,        String
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

  attribute :id,          Integer
  attribute :property_id, String
  attribute :unit_id,     String
  attribute :check_in,    String
  attribute :check_out,   String
  attribute :guests,      Integer
  attribute :code,        String
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

  attribute :id,           Integer
  attribute :supplier_id,  Integer
  attribute :identifier,   String
  attribute :username,     String
  attribute :access_token, String
  attribute :next_run_at,  Time
  attribute :created_at,   Time
  attribute :updated_at,   Time
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

  attribute :id,                 Integer
  attribute :host_id,            Integer
  attribute :started_at,         Time
  attribute :finished_at,        Time
  attribute :successful,         Boolean
  attribute :properties_created, Integer
  attribute :properties_updated, Integer
  attribute :properties_deleted, Integer
  attribute :created_at,         Time
  attribute :updated_at,         Time
end

collection :background_workers do
  entity     BackgroundWorker
  repository BackgroundWorkerRepository

  attribute :id,          Integer
  attribute :supplier_id, Integer
  attribute :next_run_at, Time
  attribute :interval,    Integer
  attribute :type,        String
  attribute :status,      String
  attribute :created_at,  Time
  attribute :updated_at,  Time
end
