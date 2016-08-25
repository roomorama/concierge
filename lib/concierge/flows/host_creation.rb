module Concierge::Flows

  # +Concierge::Flows::BackgroundWorkerCreation+
  #
  # This class encapsulates the flow of creating a background worker for a given
  # supplier, validating the parameters and interpreting human-readable interval
  # times, such as "1d" for one day, and generating the resulting number of seconds
  # to be stored in the database.
  class BackgroundWorkerCreation
    include Hanami::Validations

    INTERVAL_FORMAT = /^\s*(?<amount>\d+)\s*(?<unit>[smhd])\s*$/

    attribute :supplier_id
    attribute :host_id
    attribute :interval, presence: true, format:    INTERVAL_FORMAT
    attribute :type,     presence: true, inclusion: BackgroundWorker::TYPES
    attribute :status,   presence: true, inclusion: BackgroundWorker::STATUSES

    attr_reader :worker_lookup

    # The worker lookup classes below are expected to implement two methods
    #
    # +find_existing+ (type: String)
    # Searches the +background_workers+ table for a record associated with the
    # record (host or supplier) given on initialization of the given +type+.
    # If found, the method is supposed to return a +BackgroundWorker+ instance;
    # otherwise +nil+.
    #
    # +build_new+
    # Builds a new, non-persisted +BackgroundWorker+ instance associated with
    # the given record (host or supplier)
    #
    # Each different implementation performs the operation above for either
    # +Host+ or +Supplier+.

    # +Concierge::Flows::BackgroundWorkerCreation::HostWorkerLookup+
    #
    # This class knows how to lookup background workers associated with
    # hosts.
    class HostWorkerLookup
      attr_reader :host

      # host - a +Host+ instance.
      def initialize(host)
        @host = host
      end

      def find_existing(type)
        workers = BackgroundWorkerRepository.for_host(host)
        workers.find { |worker| worker.type == type }
      end

      def build_new
        BackgroundWorker.new(host_id: host.id)
      end
    end

    # +Concierge::Flows::BackgroundWorkerCreation::HostWorkerLookup+
    #
    # This class knows how to lookup background workers associated with
    # suppliers (for aggregated synchronisation processes).
    class SupplierWorkerLookup
      attr_reader :supplier

      # supplier - a +Supplier+ instance.
      def initialize(supplier)
        @supplier = supplier
      end

      def find_existing(type)
        workers = BackgroundWorkerRepository.for_supplier(supplier)
        workers.find { |worker| worker.type == type }
      end

      def build_new
        BackgroundWorker.new(supplier_id: supplier.id)
      end
    end

    # overrides the class initialization (already provided by +Hanami::Validations+)
    # in order to read the +worker_lookup+ attribute, which should be an instance
    # of either +HostWorkerLookup+ or +SupplierWorkerLookup+.
    def initialize(attributes)
      @worker_lookup = attributes.delete(:worker_lookup)
      super
    end

    # apart from the validations already performed by the attributes declaration in
    # this class, this method makes sure that at least one of +supplier_id+ or +host_id+
    # are given. This is to ensure no instances will be created without proper foreign
    # keys (or with duplicated foreign keys.)
    def valid?
      builtin_validations = super

      has_host_id         = host_id.to_i > 0
      has_supplier_id     = supplier_id.to_i > 0

      # if a host id was given, the record is only valid if *no supplier id was given*
      # (since only one must be set at a time); otherwise, it needs to have a supplier id.
      valid_foreign_key = has_host_id ? (!has_supplier_id) : has_supplier_id

      builtin_validations && valid_foreign_key
    end

    def perform
      if valid?
        worker = worker_lookup.find_existing(type) || worker_lookup.build_new

        # set the values passed to make sure that changes in the parameters update
        # existing records.
        worker.interval = interpret_interval(interval)
        worker.type     = type
        worker.status   = status

        worker = BackgroundWorkerRepository.persist(worker)
        Result.new(worker)
      else
        Result.error(:invalid_parameters)
      end
    end

    private

    def interpret_interval(interval)
      match    = INTERVAL_FORMAT.match(interval)
      absolute = match[:amount].to_i

      case match[:unit]
      when "s"
        absolute
      when "m"
        absolute * 60
      when "h"
        absolute * 60 * 60
      when "d"
        absolute * 60 * 60 * 24
      end
    end

    def host
      @host ||= HostRepository.find(host_id)
    end

    def supplier
      @supplier ||= SupplierRepository.find(supplier_id)
    end

    def attributes
      to_h
    end
  end

  # +Concierge::Flows::HostCreation+
  #
  # This class encapsulates the creation of host, a including associated
  # background workers. Hosts belong to a supplier and other related
  # attributes.
  class HostCreation
    include Hanami::Validations

    IDLE = "idle"

    attribute :supplier,       presence: true
    attribute :identifier,     presence: true
    attribute :username,       presence: true
    attribute :access_token,   presence: true
    attribute :fee_percentage, presence: true

    attr_reader :config_path

    # overrides the initializer definition by +Hanami::Validations+ to read the
    # required +config_path+ option that indicates the path to the +suppliers.yml+
    # file to read the workers definition.
    def initialize(attributes)
      @config_path = attributes.delete(:config_path)
      super
    end

    # creates database records for the host, as well as associated workers.
    # Parses the +config/suppliers.yml+ file to read the workers definition
    # for the supplier the host belongs to.
    def perform
      if valid?
        transaction do
          host = create_host
          workers_definition = find_workers_definition

          return workers_definition unless workers_definition.success?

          workers_definition.value.each do |type, data|
            data = data.to_h

            validation = compile_definition(data)
            return validation unless validation.success?

            # if there is an +absence+ field for a given worker definition, it means
            # the worker is not supported, and the +absence+ field indicates the reason
            # that worker is not implemented for a given supplier.
            #
            # In such case, the +BackgroundWorker+ record should not be created.
            next if data["absence"]

            attributes = worker_attributes(host, supplier, type, data)
            BackgroundWorkerCreation.new(attributes).perform.tap do |result|
              return result unless result.success?
            end
          end

          Result.new(host)
        end
      else
        Result.error(:invalid_parameters)
      end
    end

    private

    def create_host
      existing = HostRepository.from_supplier(supplier).identified_by(identifier).first
      host = existing || Host.new(supplier_id: supplier.id, identifier: identifier)

      host.username       = username
      host.access_token   = access_token
      host.fee_percentage = fee_percentage.to_f
      HostRepository.persist(host)
    end

    def find_workers_definition
      definition = nil

      suppliers_config.find do |name, workers|
        if name == supplier.name
          definition = workers
        end
      end

      if definition
        Result.new(definition["workers"].to_h)
      else
        Result.error(:no_workers_definition)
      end
    end

    # makes sure there are no conflicting keys in a worker definition.
    # Namely:
    #
    # * if the +absence+ field is declared, there is no point to have either
    #   the +every+ or the +aggregated+ field. That is flagged as an error.
    #
    # Returns a +Result+ instance indicating whether or not the +definition+
    # given is valid.
    def compile_definition(definition)
      absence    = definition.key?("absence")
      interval   = definition.key?("every")
      aggregated = definition.key?("aggregated")

      if absence && (interval || aggregated)
        Result.error(:invalid_worker_definition)
      else
        Result.new(definition)
      end
    end

    def worker_attributes(host, supplier, type, data)
      if data["aggregated"]
        attributes = {
          supplier_id:   supplier.id,
          worker_lookup: Concierge::Flows::BackgroundWorkerCreation::SupplierWorkerLookup.new(supplier)
        }
      else
        attributes = {
          host_id:       host.id,
          worker_lookup: Concierge::Flows::BackgroundWorkerCreation::HostWorkerLookup.new(host)
        }
      end

      {
        interval: data["every"],
        type:     type.to_s,
        status:   IDLE
      }.merge!(attributes)
    end

    def suppliers_config
      @config ||= YAML.load_file(config_path)
    end

    def transaction
      result = nil
      HostRepository.transaction { result = yield }
      result
    end

    def attributes
      to_h
    end
  end

end
