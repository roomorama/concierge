require 'hanami/model'
Dir["#{ __dir__ }/concierge/**/*.rb"].sort.each { |file| require_relative file }

Hanami::Model.configure do
  adapter type: :sql, uri: ENV['CONCIERGE_DATABASE_URL']

  migrations 'db/migrations'
  schema     'db/schema.sql'

  mapping Hanami.root.join("config", "mapping").to_s
end.load!

module Concierge
  def self.app
    @_app ||=  ENV["CONCIERGE_APP"].downcase.to_sym
  end
end
