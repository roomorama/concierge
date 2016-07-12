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

    attribute :supplier_id, presence: true
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
      workers = BackgroundWorkerRepository.for_supplier(supplier).to_a
      workers.find { |worker| worker.type == type }
    end

    def build_new
      BackgroundWorker.new(supplier_id: supplier_id)
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

    def supplier
      @supplier ||= SupplierRepository.find(supplier_id)
    end

    def attributes
      to_h
    end
  end

  # +Concierge::Flows::SupplierCreation+
  #
  # This class encapsulates the creation of supplier, a including associated
  # background workers. Suppleirs are composed of a +name+ only. A definition of
  # the workers is also expected by this class.
  class SupplierCreation
    include Hanami::Validations

    attribute :name,    presence: true
    attribute :workers, presence: true

    # creates database records for the supplier and background workers.
    # Returns a +Result+ instance wrapping the resulting +Supplier+ instance,
    # or an error in case the parameters are not valid.
    def perform
      if valid?
        name     = attributes[:name]
        supplier = SupplierRepository.named(name) || create_supplier(attributes[:name])

        attributes[:workers].each do |type, data|
          result = BackgroundWorkerCreation.new(
            supplier_id: supplier.id,
            interval:    data[:every],
            type:        type.to_s,
            status:      "idle"
          ).perform

          return result unless result.success?
        end

        Result.new(supplier)
      else
        Result.error(:invalid_parameters)
      end
    end

    private

    def create_supplier(name)
      SupplierRepository.create(
        Supplier.new(name: attributes[:name])
      )
    end

    def attributes
      to_h
    end
  end

end
