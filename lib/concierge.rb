require 'hanami/model'
require_relative "concierge/entities/ext/pg_json"

Dir["#{ __dir__ }/concierge/**/*.rb"].sort.each { |file| require_relative file }

Hanami::Model.configure do
  adapter type: :sql, uri: ENV['CONCIERGE_DATABASE_URL']

  migrations 'db/migrations'
  schema     'db/schema.sql'

  mapping Hanami.root.join("config", "mapping").to_s
end.load!

module Concierge
  def self.app
    @_app ||=  ENV["CONCIERGE_APP"]&.downcase&.to_sym
  end

  class << self
    # the +context+ variable on +Concierge+ holds the current request
    # context. On most cases, it will hold an instance of +Concierge::Context+
    # that aggregates data related to the running transaction (be it
    # an API request or a job processing task.)
    attr_accessor :context
  end

  # by default, initialize the context to a null implementation, which does
  # not collect event data. Applications that wish to make use of transaction
  # context should set +Concierge.context+ to a new instance of +Concierge::Context+
  # accordingly.
  self.context = Concierge::Context::Null.new
end
