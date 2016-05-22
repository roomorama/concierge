collection :external_errors do
  entity     ExternalError
  repository ExternalErrorRepository

  attribute :id,          Integer
  attribute :operation,   String
  attribute :supplier,    String
  attribute :code,        String
  attribute :context,     Concierge::HStore
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
