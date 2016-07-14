module Concierge::Flows

  # +Concierge::Flows::ExternalErrorCreation+
  #
  # This use case class wraps the creation of an +ExternalError+ record, performing
  # attribute validations prior to triggering the database call.
  #
  # All parameters must be present, and the operation given must be declared under
  # +ExternalError::OPERATIONS+.
  class ExternalErrorCreation
    include Hanami::Validations

    attribute :operation,   presence: true, inclusion: ExternalError::OPERATIONS
    attribute :supplier,    presence: true
    attribute :code,        presence: true
    attribute :context,     presence: true
    attribute :happened_at, presence: true

    # Creates a new entry on the +external_errors+ database table. If one of the
    # parameters do not match existing validations, this method is a no-op.
    def perform
      if valid?
        error = ExternalError.new(attributes)
        database.create(error)
      end
    end

    private

    def attributes
      to_h
    end

    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(ExternalErrorRepository)
    end
  end

end

# whenever an external error happens, persist it to the database.
Concierge::Announcer.on(Concierge::Errors::EXTERNAL_ERROR) do |params|
  Concierge::Flows::ExternalErrorCreation.new(params).perform
end
