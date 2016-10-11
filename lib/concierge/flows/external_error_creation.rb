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

    # Notifies exception tracker
    class ErrorReporter
      attr_reader :ext_error

      def initialize(ext_error)
        @ext_error = ext_error
      end

      def report
        Rollbar.warning(error_message, custom_attributes)
      end

      private
      def error_message
        "#{error_message_prefix}: #{error_message_body}"
      end

      def custom_attributes
        {
          external_error_id: ext_error.id,
          code:              ext_error.code,
          operation:         ext_error.operation,
          supplier:          ext_error.supplier,
          happened_at:       ext_error.happened_at
        }
      end

      def error_message_prefix
        [ext_error.supplier, ext_error.operation, ext_error.code].join(" ")
      end

      def error_message_body
        ext_error.description[0..100]
      end
    end

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
        database.create(error).tap do |record|
          ErrorReporter.new(record).report if record
        end
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
  end

end

# whenever an external error happens, persist it to the database.
Concierge::Announcer.on(Concierge::Errors::EXTERNAL_ERROR) do |params|
  Concierge::Flows::ExternalErrorCreation.new(params).perform
end
