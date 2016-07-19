class Workers::OperationRunner

  # +Workers::OperationRunner::UpdateCalendar+
  #
  # This class encapsulates the operation of updating the availabilities calendar
  # of a property on Roomorama.
  class UpdateCalendar

    attr_reader :operation, :roomorama_client

    # operation - a +Roomorama::Client::Operations::Diff+ instance
    # client    - a +Roomorama::Client+ instance properly configured
    def initialize(operation, client)
      @operation        = operation
      @roomorama_client = client
    end

    # calendar - a +Roomorama::Calendar+ instance representing the changes to
    #            be applied to a property's availability calendar.
    #
    # Returns a +Result+ that, when successful, wraps the given calendar instance.
    def perform(calendar)
      result = roomorama_client.perform(operation)
      return result unless result.success?

      Result.new(calendar)
    end
  end
end
