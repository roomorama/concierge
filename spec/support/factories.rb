module Support

  # +Support::Factories+
  #
  # This module provides a collection of methods for easily creating Concierge
  # entities. For each method, a set of defaults is assumed, which can be
  # overwritten by passing a hash of attributes to each of them.
  module Factories
    def create_sync_process(overrides = {})
      attributes  = {
        type:        "metadata",
        successful:  true,
        started_at:  Time.now - 10 * 60, # 10 minutes ago
        finished_at: Time.now
      }.merge(overrides)

      attributes[:host_id] ||= create_host.id

      process = SyncProcess.new(attributes)
      SyncProcessRepository.create(process)
    end

    def create_reservation(overrides = {})
      attributes = {
        supplier:         "Supplier X",
        check_in:         Date.today.to_s,
        check_out:        (Date.today + 3).to_s,
        guests:           2,
        reference_number: "ABC123",
      }.merge(overrides)

      attributes[:property_id] ||= create_property.id

      reservation = Reservation.new(attributes)
      ReservationRepository.create(reservation)
    end

    def create_property(overrides = {})
      attributes = {
        identifier: "PROP1",
        data:       {
          title: "Studio Apartment in Madrid",
          type:  "bnb",
          nightly_rate: 10,
          images: [
            { identifier: "PROP1IMAGE", url: "https://www.example.org/image.png" }
          ]
        },
      }.merge(overrides)

      attributes[:host_id] ||= create_host.id

      attributes[:data][:identifier] = attributes[:identifier]
      property = Property.new(attributes)
      PropertyRepository.create(property)
    end

    def create_host(overrides = {})
      attributes = {
        identifier:     "host",
        username:       "concierge_host",
        access_token:   SecureRandom.hex(32),
        fee_percentage: 0,
      }.merge(overrides)

      attributes[:supplier_id] ||= create_supplier.id

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

    def create_overwrite(overrides = {})
      attributes = {
        host_id: create_host.id,
        property_identifier: SecureRandom.hex(3),
        data: { "cancellation_policy" => "flexible" }
      }.merge(overrides)

      overwrite = Overwrite.new(attributes)
      OverwriteRepository.create(overwrite)
    end
  end

end
