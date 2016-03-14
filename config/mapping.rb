collection :external_errors do
  entity     ExternalError
  repository ExternalErrorRepository

  attribute :id,          Integer
  attribute :operation,   String
  attribute :supplier,    String
  attribute :code,        String
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
