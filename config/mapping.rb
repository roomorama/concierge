collection :external_errors do
  entity     ExternalError
  repository ExternalErrorRepository

  attribute :id,          Integer
  attribute :operation,   String
  attribute :supplier,    String
  attribute :code,        String
  attribute :context,     Concierge::PGJSON
  attribute :message,     String
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
