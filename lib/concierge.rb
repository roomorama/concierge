require 'hanami/model'
require 'hanami/mailer'
Dir["#{ __dir__ }/concierge/**/*.rb"].each { |file| require_relative file }

Hanami::Model.configure do
  adapter type: :sql, uri: ENV['CONCIERGE_DATABASE_URL']

  migrations 'db/migrations'
  schema     'db/schema.sql'

  mapping Hanami.root.join("config", "mapping").to_s
end.load!
