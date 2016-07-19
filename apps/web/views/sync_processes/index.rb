module Web::Views::SyncProcesses

  # +Web::Views::SyncProcesses::Index+
  #
  # The sync processes index page renders a table of synchronisation processes
  # that have been executed recently.
  class Index
    include Web::View

    # queries for the +Host+ instance associated with the given +SyncProcess+.
    def host_for(sync)
      HostRepository.find(sync.host_id)
    end

    # looks up the +Supplier+ instance that owns the given +Host+ instance.
    def supplier_for(host)
      SupplierRepository.find(host.supplier_id)
    end

    # Receives an timestamp and formats it for display.
    def format_time(timestamp)
      timestamp.strftime("%B %d, %Y at %H:%M")
    end
  end
end
