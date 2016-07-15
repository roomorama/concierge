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

    attribute :host_id,     presence: true
    attribute :interval,    presence: true, format:    INTERVAL_FORMAT
    attribute :type,        presence: true, inclusion: BackgroundWorker::TYPES
    attribute :status,      presence: true, inclusion: BackgroundWorker::STATUSES

    def perform
      if valid?
        worker = find_existing || build_new

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

    def find_existing
      workers = BackgroundWorkerRepository.for_host(host).to_a
      workers.find { |worker| worker.type == type }
    end

    def build_new
      BackgroundWorker.new(host_id: host_id)
    end

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
            result = BackgroundWorkerCreation.new(
              host_id:     host.id,
              interval:    data.to_h["every"],
              type:        type.to_s,
              status:      "idle"
            ).perform

            return result unless result.success?
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
