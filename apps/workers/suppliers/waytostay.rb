module Workers::Suppliers

  class Waytostay

    attr_reader :synchronisation, :host, :client

    def initialize(host)
      @host = host
      @synchronisation = Workers::Synchronisation.new(host)
      synchronisation.skip_purge!
      @client = ::Waytostay::Client.new
    end

    def perform
      changes = get_new_waytostay_changes
      return if changes.nil?

      uniq_properties_in(changes).each do |property_ref|
        synchronisation.start(property_ref) do
          wrapped_property = if changes[:properties].include? property_ref
                               # get the updated property from supplier
                               client.get_property(property_ref)
                             else
                               # no changes on property attributes indicated, just
                               # load one from db so we can attach other changes
                               load_existing property_ref
                             end
          next wrapped_property unless wrapped_property.success?

          if changes[:media].include? property_ref
            wrapped_property = client.update_media(wrapped_property.result)
            next wrapped_property unless wrapped_property.success?
          end

          if changes[:availability].include? property_ref
            # TODO: announce calendar sync event instead
            wrapped_property = client.update_availabilities(wrapped_property.result)
            next wrapped_property unless wrapped_property.success?
          end

          # TODO: rates, bookings
          # client.fetch_rates(property_ref) if changes[:rates].include property_ref

          wrapped_property
        end
      end

      synchronisation.finish!
    end

    private

    # Starts a new context, run the block that augments to context
    # Then announce if any error was returned from the block
    def get_new_waytostay_changes
      initialize_overall_sync_context
      result = client.get_changes_since(last_synced_timestamp)
      announce_error(result) unless result.success?
      result.value
    end

    def announce_error(result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   "sync",
        supplier:    ::Waytostay::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def initialize_overall_sync_context
      Concierge.context = Concierge::Context.new(type: "batch")
      sync_process = Concierge::Context::SyncProcess.new(
        host_id:    host.id,
        identifier: nil
      )
      Concierge.context.augment(sync_process)
    end

    # Flatten and compact the `changes` hash
    # `changes` is returned from waytostay client, looking something like:
    # { properties: ["a", "b", "c"], media: ["c", "d"] }
    #
    # The method returns ["a", "b", "c", "d"]
    #
    def uniq_properties_in(changes)
      changes.values.reduce(&:+).uniq
    end

    def last_synced_timestamp
      most_recent = SyncProcessRepository.recent_successful_sync_for_host(host).first
      most_recent&.started_at
    end

    # Returns an existing +Roomorama::Property+
    #
    def load_existing(ref)
      existing = PropertyRepository.from_host(host).identified_by(ref).first
      Roomorama::Property.load(existing.data.merge(identifier: ref))
    end

  end
end

Concierge::Announcer.on("sync.waytostay") do |host|
  Workers::Suppliers::Waytostay.new(host).perform
end

