module Web::Views::Suppliers

  # +Web::Views::Suppliers::Show+
  #
  class Show
    include Web::View

    NO_WORKERS_DEFINED = "No definition found. Please report this to the Roomorama developers."
    NO_METADATA_SYNC   = "This supplier does not synchronise metadata."
    NO_CALENDAR_SYNC   = "This supplier does not synchronise calendar."

    # calculates the number of properties provided by a given +Supplier+
    # instance given, and returns the total in a human-readable format.
    def supplier_properties(supplier)
      total = PropertyRepository.from_supplier(supplier).count
      number_formatter.present(total)
    end

    # calculates the number of properties provided by a single +Host+ given
    # and returns the total in a human-readable format.
    def host_properties(host)
      total = PropertyRepository.from_host(host).count
      number_formatter.present(total)
    end

    # formats the +fee+, given as a float, to a percentage notation, with a single
    # digit precision.
    #
    # Example
    #
    #   host.fee_percentage                        # => 8.0
    #   format_fee_percentage(host.fee_percentage) # => "8.0%"
    def format_fee_percentage(fee)
      sprintf("%.1f%", fee)
    end

    # in order not to show the access token used by a host in its entirety,
    # this extracts the first 5 digits of a +Host+ access token, and appends
    # +...+ to indicate the content is just a substring.
    #
    # Example
    #
    #   host.access_token         # => "807fac8ccd416ff60987b5b6213f5d2338714214b9adff9f16bb6765d9a42186"
    #   format_access_token(host) # => "807fa..."
    def format_access_token(host)
      reveal = host.access_token.chars.first(5).join
      [reveal, "..."].join
    end

    # Determines the frequency of the +metadata+ worker for a given +Supplier+,
    # and returns the information as a human-readable description (+String+).
    #
    # Example
    #
    #   # in config/suppliers.yml
    #   SupplierX:
    #     workers:
    #       metadata:
    #         every: "1d"
    #   supplier.name                # => "SupplierX"
    #   metadata_frequency(supplier) # => "every day"
    #
    # If there are no +workers+ entry or no +metadata+ entry in the workers
    # definition on +config/suppliers.yml+, this method returns +NO_WORKERS_DEFINED+.
    def metadata_frequency(supplier)
      definition = Concierge::SupplierConfig.for(supplier.name)
      unless definition && definition["workers"]
        return NO_WORKERS_DEFINED
      end

      definition = definition["workers"]
      metadata = definition["metadata"]
      if metadata["every"]
        format_frequency(metadata["every"])
      elsif metadata["absence"]
        metadata["absence"]
      else
        NO_METADATA_SYNC
      end
    end

    # Determines the frequency of the +calendar+ worker for a given +Supplier+,
    # and returns the information as a human-readable description (+String+).
    #
    # The +calendar+ worker frequency is determined by the +availabilities+ entry
    # on +config/suppliers.yml+.
    #
    # Example
    #
    #   # in config/suppliers.yml
    #   SupplierX:
    #     workers:
    #       availabilities:
    #         every: "1d"
    #   supplier.name                # => "SupplierX"
    #   metadata_frequency(supplier) # => "every day"
    #
    # If there are no +workers+ entry or no +metadata+ entry in the workers
    # definition on +config/suppliers.yml+, this method returns +NO_WORKERS_DEFINED+.
    def availabilities_frequency(supplier)
      definition = Concierge::SupplierConfig.for(supplier.name)
      unless definition && definition["workers"]
        return NO_WORKERS_DEFINED
      end

      definition = definition["workers"]
      return NO_CALENDAR_SYNC unless definition && definition["availabilities"]

      availabilities = definition["availabilities"]
      if availabilities["every"]
        format_frequency(availabilities["every"])
      elsif availabilities["absence"]
        availabilities["absence"]
      else
        NO_CALENDAR_SYNC
      end
    end

    def aggregated_label(type)
      if aggregated?(type)
        html.span "*", class: "aggregated-label"
      end
    end

    def aggregated?(type)
      definitions     = Concierge::SupplierConfig.for(supplier.name)
      type_definition = definitions && definitions[type]

      !!(type_definition && type_definition["aggregated"])
    end

    def any_aggregated_worker?
      aggregated?("metadata") || aggregated?("availabilities")
    end

    def workers_for(host)
      BackgroundWorkerRepository.for_host(host)
    end

    def aggregated_workers_for(supplier)
      BackgroundWorkerRepository.for_supplier(supplier)
    end

    def overwrite_count_for(host)
      count = OverwriteRepository.for_host_id(host.id).count
      "#{count} overwrite#{'s' if count > 1}"
    end

    # Creates an HTML button/label for the status of a worker. +status+ is expected
    # to be a +String+ equal to one of +BackgroundWorker::STATUSES+.
    def status_label(status)
      css_class = {
        idle:    "secondary-button",
        queued:  "warning-button",
        running: "success-button"
      }.fetch(status.to_sym, "warning-button")

      html.button status, class: [css_class, " pure-button"].join
    end

    # Receives an instance of +BackgroundWorker+ and formats the
    # +next_run_at+ column for display.
    #
    # If that column is +null+, meaning the worker has just been created
    # and have never been run yet, the message indicates that the worker
    # will be kicked in soon (time varies depending of when the scheduler
    # will run next - see +Workers::Scheduler+).
    def format_time(worker)
      next_run_at = worker.next_run_at
      next_run_at ? time_formatter.present(next_run_at) : "Soon (in at most 10 minutes)"
    end

    private

    def number_formatter
      @number_formatter ||= Web::Support::Formatters::Number.new
    end

    def time_formatter
      @time_formatter ||= Web::Support::Formatters::Time.new
    end

    # used when priting frequencies of workers for suppliers. The +frequency+
    # argument given is the +String+ declared on +config/suppliers.yml+ and is
    # in the format +1d+, +5h+ and the like.
    def format_frequency(frequency)
      format = Concierge::Flows::BackgroundWorkerCreation::INTERVAL_FORMAT
      match  = format.match(frequency)

      amount = match[:amount].to_i
      unit   = match[:unit]

      unit_name = {
        "s" => "second",
        "m" => "minute",
        "h" => "hour",
        "d" => "day"
      }.fetch(unit)

      # if the +amount+ is larger than one, we need to pluralize (luckily this means
      # just appending an +s+ for the units involved) and use that as a quantifier.
      #
      # If the amount is +1+, we can just skip it (+every 1 day+ sounds more natural
      # as +every day+).
      if amount > 1
        unit_name += "s"
        quantifier = amount
      else
        quantifier = ""
      end

      ["every", quantifier, unit_name].join(" ")
    end
  end
end
