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

    # returns the CSS class to be applied on the +tr+ element of a sync process
    # row which indicates whether or not it completed successfully.
    def worker_status_row(sync)
      if sync.successful
        "concierge-success-row"
      else
        "concierge-failed-row"
      end
    end

    # looks up the +Supplier+ instance that owns the given +Host+ instance.
    def supplier_for(host)
      SupplierRepository.find(host.supplier_id)
    end

    # formats a number given +n+ for presentation
    def format_number(n)
      number_formatter.present(n)
    end

    # Receives an timestamp and formats it for display.
    def format_time(timestamp)
      time_formatter.present(timestamp)
    end

    private

    def number_formatter
      @number_formatter ||= Web::Support::Formatters::Number.new
    end

    def time_formatter
      @time_formatter ||= Web::Support::Formatters::Time.new
    end
  end
end
