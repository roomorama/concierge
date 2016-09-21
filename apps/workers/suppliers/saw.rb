module Workers::Suppliers
  # +Workers::Suppliers::SAW+
  #
  # Performs synchronisation with supplier
  class SAW
    attr_reader :synchronisation, :host

    def initialize(host)
      @host = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      result = synchronisation.new_context { importer.fetch_countries }

      if result.success?
        countries = result.value
      else
        message = "Failed to perform the `#fetch_countries` operation"
        announce_error(message, result)
        return
      end

      result = synchronisation.new_context do
        importer.fetch_properties_by_countries(countries)
      end

      if result.success?
        properties = result.value
      else
        message = "Failed to perform the `#fetch_properties_by_countries` operation"
        announce_error(message, result)
        return
      end

      result = synchronisation.new_context do
        importer.fetch_all_unit_rates_for_properties(properties)
      end

      if result.success?
        all_unit_rates = result.value
      else
        message = "Failed to perform the `#fetch_all_unit_rates_for_properties` operation"
        announce_error(message, result)
        return
      end

      properties.each do |property|
        result = importer.fetch_detailed_property(property.internal_id)
        if result.success?
          detailed_property = result.value

          next if skip?(detailed_property)

          synchronisation.start(property.internal_id) do
            unit_rates = find_rates(property.internal_id, all_unit_rates)
            Result.new ::SAW::Mappers::RoomoramaProperty.build(
              property,
              detailed_property,
              unit_rates
            )
          end
        else
          synchronisation.failed!
          # potentially a more meaningful result can be passed from HTTPClient, into result.error.data
          announce_error("Failed to perform the `#fetch_detailed_property` operation", result)
        end
      end

      synchronisation.finish!
    end

    private

    # Check if we can skip(and not publish) property, because of the following cases
    #   - Postal code is "."
    #
    # Returns true to caller if skipped
    #
    def skip?(detailed_property)
      if detailed_property.postal_code == "."
        synchronisation.skip_property(detailed_property.internal_id, "Invalid postal_code: .")
        return true
      end
      return false
    end

    def importer
      @importer ||= ::SAW::Importer.new(credentials)
    end

    def credentials
      @credentials ||= Concierge::Credentials.for(::SAW::Client::SUPPLIER_NAME)
    end

    def announce_error(message, result)
      context = Concierge::Context::Message.new(
        label: 'Synchronisation Failure',
        message: message,
        backtrace: caller
      )
      Concierge.context.augment(context)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    ::SAW::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def find_rates(property_id, all_unit_rates)
      all_unit_rates.find { |rate| rate.property_id == property_id.to_s }
    end
  end
end

Concierge::Announcer.on("metadata.SAW") do |host, args|
  Workers::Suppliers::SAW.new(host).perform
  Result.new({})
end
