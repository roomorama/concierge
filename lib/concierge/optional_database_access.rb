module Concierge

  # +Concierge::OptionalDatabaseAccess+
  #
  # In some cases, database access on Concierge is used to provide an extra
  # functionality that is not **required** in order to fulfil the current request.
  # Examples of such scenarios include the logging of external errors, network
  # response caching and general saving of metadata associated with a request.
  #
  # For such cases, there is a desire to keep database access optional.
  # In case, for some reason, there is an error when communicating with the
  # database (infra-structure problems, misconfigured schema, or even an
  # unexpected behaviour from a supplier), we want to keep processing the request
  # without failing. This is exceptionally important in the booking process.
  #
  # This class wraps a Hanami repository in order to recover from such kinds
  # of errors. It should be used whenever request processing can continue
  # successfully even if the database operation fails.
  #
  # Usage
  #
  #   # with healthy database access
  #   database = OptionalDatabaseAccess(SomeRepository)
  #   database.create(entity)
  #   SomeRepository.find(entity.id) # => #<Entity...>
  #
  #   # without database access
  #   database.update(entity)
  #   # => false
  #   # proceed with request processing.
  class OptionalDatabaseAccess

    attr_reader :repository

    # Creates a new +Concierge::OptionalDatabaseAccess+ instance.
    #
    # repository - a +Hanami+ repository.
    #
    # In fact, the repository received as argument can be any implementation
    # of a repository that implements database access through +Hanami+. It
    # needs to implement +create+, +update+ and +delete+ methods.
    def initialize(repository)
      @repository = repository
    end

    def create(record)
      with_safe_access { repository.create(record) }
    end

    def update(record)
      with_safe_access { repository.update(record) }
    end

    def delete(record)
      with_safe_access { repository.delete(record) }
    end

    private

    def with_safe_access
      yield
    rescue Hanami::Model::Error
      false
    end

  end
end
