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

  # +Concierge::Flows::HostUpsertion+
  #
  # This class encapsulates the creation of host, a including associated
  # background workers. Hosts belong to a supplier and other related
  # attributes.
  #
  # A Roomorama::CreateHost operation will be run on every #perform,
  # which behaves more or less like upsert, except for AccessToken.
  # The same AccessToken is always returned for the same Roomorama username
  #
  class HostUpsertion
    include Concierge::JSON
    include Hanami::Validations

    IDLE = "idle"

    attribute :supplier,       presence: true
    attribute :identifier,     presence: true
    attribute :username,       presence: true
    attribute :fee_percentage, presence: true
    attribute :access_token
    attribute :name
    attribute :email
    attribute :phone
    attribute :payment_terms

    # creates database records for the host, as well as associated workers.
    # Parses the +config/suppliers.yml+ file to read the workers definition
    # for the supplier the host belongs to.
    def perform
      if valid?
        return Result.error(:username_already_used) if username_already_used?
        workers_definition = find_workers_definition
        return workers_definition unless workers_definition.success?

        if self.access_token.to_s.empty?
          access_token_result = create_roomorama_user
          return access_token_result unless access_token_result.success?
          self.access_token = access_token_result.value
        end
        transaction do
          host = create_host

          workers_definition.value.each do |type, data|
            data = data.to_h

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

    def username_already_used?
      HostRepository.with_username(username).count > 0
    end

    def create_roomorama_user
      client = Roomorama::Client.new(ENV["CONCIERGE_CREATE_HOST_TOKEN"])
      creation = Roomorama::Client::Operations::CreateHost.new(supplier, username, name, email, phone, payment_terms)
      Concierge.context = Concierge::Context.new(type: "host_creation")
      post_result = client.perform(creation)
      return post_result unless post_result.success?
      decode_result = json_decode(post_result.value.body)

      if decode_result.success?
        return Result.new(decode_result.value["access_token"])
      else
        return decode_result
      end
    end

    def create_host
      existing = HostRepository.from_supplier(supplier).identified_by(identifier).first
      host = existing || Host.new(supplier_id: supplier.id, identifier: identifier)

      host.username       = username
      host.access_token   = access_token
      host.fee_percentage = fee_percentage.to_f
      host.email          = email
      host.name           = name
      host.phone          = phone
      host.payment_terms  = payment_terms
      HostRepository.persist(host)
    end

    def find_workers_definition
      definition = Concierge::SupplierConfig.for(supplier.name)

      if definition
        Result.new(definition["workers"].to_h)
      else
        Result.error(:no_workers_definition)
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
