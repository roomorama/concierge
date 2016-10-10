module Concierge::Flows

  # +Concierge::Flows::ExternalErrorCreation+
  #
  # This use case class wraps the creation of an +ExternalError+ record, performing
  # attribute validations prior to triggering the database call.
  #
  # All parameters except +description+ must be present, and the operation
  # given must be declared under +ExternalError::OPERATIONS+.
  class ExternalErrorCreation
    include Hanami::Validations

    attribute :operation,   presence: true, inclusion: ExternalError::OPERATIONS
    attribute :supplier,    presence: true
    attribute :code,        presence: true
    attribute :description
    attribute :context,     presence: true
    attribute :happened_at, presence: true

    # Creates a new entry on the +external_errors+ database table. If one of the
    # parameters do not match existing validations, this method is a no-op.
    def perform
      if valid?
        error = ExternalError.new(attributes)
        record = database.create(error)

        report_error(record) if record

        record
      end
    end

    private
    def attributes
      to_h.merge(description: truncated_description)
    end

    def truncated_description
      description.to_s[0...2000]
    end

    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(ExternalErrorRepository)
    end

    def report_error(error)
      Rollbar.error(
        error.description,
        external_error_id: error.id,
        code:              error.code,
        operation:         error.operation,
        supplier:          error.supplier,
        happened_at:       error.happened_at
      )
    end
  end

end

# whenever an external error happens, persist it to the database.
Concierge::Announcer.on(Concierge::Errors::EXTERNAL_ERROR) do |params|
  Concierge::Flows::ExternalErrorCreation.new(params).perform
end
