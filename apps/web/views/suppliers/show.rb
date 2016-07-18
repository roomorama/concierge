module Web::Views::Suppliers

  # +Web::Views::Suppliers::Show+
  #
  class Show
    include Web::View

    NO_WORKERS_DEFINED = "No definition found. Please report this to the Roomorama developers."
    NO_CALENDAR_SYNC   = "This supplier does not synchronise calendar."

    # calculates the number of properties provided by a given +Supplier+
    # instance given, and returns the total in a human-readable format.
    def supplier_properties(supplier)
      total = PropertyRepository.from_supplier(supplier).count
      format_number(total)
    end

    # calculates the number of properties provided by a single +Host+ given
    # and returns the total in a human-readable format.
    def host_properties(host)
      total = PropertyRepository.from_host(host).count
      format_number(total)
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
      definition = workers_definitions[supplier.name]
      unless definition && definition["workers"]
        return NO_WORKERS_DEFINED
      end

      definition = definition["workers"]
      format_frequency(definition["metadata"]["every"])
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
    def calendar_frequency(supplier)
      definition = workers_definitions[supplier.name]
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

    private

    # converts a number to its more human-readable version including commas
    # to separate thousands.
    #
    # Example:
    #
    #   format_number(27840) # => "27,840"
    def format_number(n)
      n.               # 27840
        to_s.          # "27840"
        chars.         # ["2", "7", "8", "4", "0"]
        reverse.       # ["0", "4", "8", "7", "2"]
        each_slice(3). # Enumerator
        to_a.          # [["0", "4", "8"], ["7", "2"]]
        map(&:join).   # ["048", "72"]
        join(",").     # "048,72"
        reverse        # "27,840"
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

    def workers_definitions
      @definitions ||= YAML.load_file(Hanami.root.join("config", "suppliers.yml").to_s)
    end
  end
end
