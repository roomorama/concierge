module Workers

  # +Workers::OperationRunner+
  #
  # This class encapsulates the running of an operation, in the +Roomorama::Client+
  # sense of it. Depending on the type of the operation to be performed, it also
  # updates Concierge's database accordingly, through the instantiation of one of
  # the classes under +Workers::OperationRunner+. See their documentation for
  # more information.
  #
  # Usage
  #
  #   operation = Roomorama::Client::Operations.publish(property)
  #   runner = Workers::OperationRunner.new(host)
  #   result = runner.perform(operation, property)
  #
  #   if result.success?
  #     move_on
  #   else
  #     handle_failure(result.error)
  #   end
  class OperationRunner

    # +Workers::OperationRunner::InvalidOperationError+
    #
    # This error is raised if an +operation+ is given which is not recognised
    # by the runner.
    class InvalidOperationError < StandardError
      def initialize(operation)
        super("Operation of type #{operation.class} is invalid.")
      end
    end

    attr_reader :host

    # host - expected to be a +Host+ instance.
    def initialize(host)
      @host = host
    end

    # operation - +publish+, +diff+ or +disable+ operations.
    #
    # Extra arguments depend on the specific implementation of the runner.
    # Check particular classes for more information.
    def perform(operation, *args)
      runner_for(operation).perform(*args).tap do |result|
        update_next_run if result.success?
      end
    end

    private

    def runner_for(operation)
      case operation
      when Roomorama::Client::Operations::Publish
        Workers::OperationRunner::Publish.new(host, operation, roomorama_client)
      when Roomorama::Client::Operations::Diff
        Workers::OperationRunner::Diff.new(host, operation, roomorama_client)
      when Roomorama::Client::Operations::Disable
        Workers::OperationRunner::Disable.new(host, operation, roomorama_client)
      else
        raise InvalidOperationError.new(operation)
      end
    end

    def roomorama_client
      @roomorama_client ||= Roomorama::Client.new(host.access_token, environment: roomorama_environment)
    end

    # use the production Roomorama API on production, falling back to staging in any
    # other environment.
    def roomorama_environment
      Hanami.env == "production" ? :production : :staging
    end

    # if the result of performing the operation was successful, we update
    # the timestamp when the next synchronisation for the given host
    # should happen.
    def update_next_run
      one_day = 24 * 60 * 60 # TODO make this a dynamic value
      host.next_run_at = Time.now + one_day

      HostRepository.update(host)
    end

  end
end
