module Workers::Suppliers

  class Waytostay

    attr_reader :property_sync, :calendar_sync, :host, :client

    def initialize(host)
      @host = host
      @property_sync = Workers::PropertySynchronisation.new(host)
      @calendar_sync = Workers::CalendarSynchronisation.new(host)
      property_sync.skip_purge!
      @client = ::Waytostay::Client.new
    end

    def perform
      synchronise
    end

    def synchronise
      changes = get_new_waytostay_changes
      return unless changes.success?

      uniq_properties_in(changes.value).each do |property_ref|
        property_sync.start(property_ref) do
          wrapped_property = if changes.value[:properties].include? property_ref
                               # get the updated property from supplier
                               client.get_property(property_ref)
                             else
                               # no changes on property attributes indicated, just
                               # load one from db so we can attach other changes
                               load_existing property_ref
                             end
          next wrapped_property unless wrapped_property.success?

          if changes.value[:media].include?(property_ref)
            wrapped_property = client.update_media(wrapped_property.result)
            next wrapped_property unless wrapped_property.success?
          end

          # TODO: bookings
          wrapped_property
        end
      end
      property_sync.finish!

      changes.value[:availability].each do |property_ref|
        sync_calendar(property_ref)
      end
      calendar_sync.finish!
    end

    private

    # Loops through all pages of waytostay new properties, yielding each
    # as a Roomorama::Property
    #
    def get_initial_properties
      initialize_overall_sync_context
      current_page = 1
      while !current_page.nil?
        result, current_page = client.get_active_properties(current_page)
        next announce_error(result) unless result.success?
        result.value.each do |property_result|
          if !property_result.success? || property_result.value.disabled
            next
          else
            yield property_result.value
          end
        end
      end
    end

    # Starts a new context, run the block that augments to context
    # Then announce if any error was returned from the block
    def get_new_waytostay_changes
      initialize_overall_sync_context
      client.get_changes_since(last_synced_timestamp).tap do |result|
        announce_error(result) unless result.success?
      end
    end

    def sync_calendar(property_ref)
      calendar_sync.start(property_ref) do

        calendar_entries_result = client.get_availabilities(property_ref)

        if calendar_entries_result.success?
          calendar = Roomorama::Calendar.new(property_ref)
          calendar_entries_result.value.each { |entry| calendar.add entry }
          Result.new(calendar)
        else
          calendar_entries_result
        end
      end
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
        worker:     Workers::PropertySynchronisation::WORKER_TYPE,
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

    # Returns the last successful time stamp of a synchronisation
    # Could be nil if there has never been a successful sync yet
    #
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

Concierge::Announcer.on("metadata.WayToStay") do |host|
  Workers::Suppliers::Waytostay.new(host).perform
end

