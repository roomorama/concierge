module Support

  # +Support::Factories+
  #
  # This module provides a collection of methods for easily creating Concierge
  # entities. For each method, a set of defaults is assumed, which can be
  # overwritten by passing a hash of attributes to each of them.
  module Factories
    def create_sync_process(overrides = {})
      attributes  = {
        type: "metadata",
        started_at: Time.now - 10 * 60, # 10 minutes ago
        finished_at: Time.now
      }.merge(overrides)

      process = SyncProcess.new(attributes)
      SyncProcessRepository.create(process)
    end

    def create_property(overrides = {})
      attributes = {
        identifier: "PROP1",
        host_id:    create_host.id,
        data:       {
          title: "Studio Apartment in Madrid",
          nightly_rate: 10,
          images: [
            { identifier: "PROP1IMAGE", url: "https://www.example.org/image.png" }
          ]
        },
      }.merge(overrides)

      property   = Property.new(attributes)
      PropertyRepository.create(property)
    end

    def create_host(overrides = {})
      attributes = {
        identifier:   "host",
        username:     "concierge_host",
        access_token: "abc123",
        supplier_id:  create_supplier.id
      }.merge(overrides)

      host = Host.new(attributes)
      HostRepository.create(host)
    end

    def create_supplier(overrides = {})
      attributes = {
        name: "Supplier A"
      }.merge(overrides)

      supplier = Supplier.new(attributes)
      SupplierRepository.create(supplier)
    end

    def create_external_error(overrides = {})
      attributes = {
        operation:   "quote",
        supplier:    "SupplierA",
        code:        "http_error",
        message:     "Network Failure",
        context:     { type: "network_failure" },
        happened_at: Time.now
      }.merge(overrides)

      error = ExternalError.new(attributes)
      ExternalErrorRepository.create(error)
    end

    def create_cache_entry(overrides = {})
      attributes = {
        key: "supplier.quote.price_call",
        value: { price: 250.0 }.to_json,
        updated_at: Time.now
      }.merge(overrides)

      entry = Concierge::Cache::Entry.new(attributes)
      Concierge::Cache::EntryRepository.create(entry)
    end

    def create_background_worker(overrides = {})
      attributes = {
        host_id:  create_host.id,
        interval: 100,
        type:     "metadata",
        status:   "idle"
      }.merge(overrides)

      worker = BackgroundWorker.new(attributes)
      BackgroundWorkerRepository.create(worker)
    end
  end

end
