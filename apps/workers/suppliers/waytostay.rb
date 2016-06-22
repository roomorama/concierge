module Workers::Suppliers

  class Waytostay

    attr_reader :synchronisation, :host, :remote

    def initialize(host)
      @host = host
      @synchronisation = Workers::Synchronisation.new(host)
      @remote = ::Waytostay::Client.new
    end

    def perform
      changes = @remote.get_changes_since(last_synced_timestamp)

      # waytostay client would already augment any error that occurs
      # when fetching changes. So we can return
      return if changes.empty?

      uniq_properties_in(changes).each do |property_ref|
        synchronisation.start(property_ref) do
          wrapped_property = if changes[:properties].include? property_ref
                               # get the updated property from supplier
                               @remote.get_property(property_ref)
                             else
                               # no changes on property attributes indicated, just
                               # load one from db so we can attache other changes
                               load_existing property_ref
                             end
          next wrapped_property unless wrapped_property.success?

          if changes[:media].include? property_ref
            wrapped_property = @remote.update_media(wrapped_property.result)
            next wrapped_property unless wrapped_property.success?
          end

          if changes[:availability].include? property_ref
            wrapped_property = @remote.update_availabilities(wrapped_property.result)
            next wrapped_property unless wrapped_property.success?
          end

          # TODO: rates, bookings
          # @remote.fetch_rates(property_ref) if changes[:rates].include property_ref

          wrapped_property
        end
      end
    end

    private

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
      # TODO: Implement this. Pending higher level last_sync_time implementions
      # TODO: Only get the last successful sync timestamp. Otherwise some changes
      # for the failed properties would be missing
      nil
    end

    # Returns an existing +Roomorama::Property+
    #
    def load_existing ref
      existing = PropertyRepository.from_host(host).identified_by(ref).first
      Roomorama::Property.load(existing.data)
    end

  end
end

Concierge::Announcer.on("sync.waytostay") do |host|
  Workers::Suppliers::Waytostay.new(host).perform
end

