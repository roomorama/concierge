collection :external_errors do
  entity     ExternalError
  repository ExternalErrorRepository

  attribute :id,          Integer
  attribute :operation,   String
  attribute :code,        String
  attribute :message,     String
  attribute :happened_at, Time
end
