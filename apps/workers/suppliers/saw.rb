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
      result = importer.fetch_countries

      if result.success?
        countries = result.value
      else
        message = "Failed to perform the `#fetch_countries` operation"
        announce_error(message, result)
        return
      end

      result = importer.fetch_available_properties_by_countries(countries)

      if result.success?
        properties = result.value
      else
        message = "Failed to perform the `#fetch_properties_by_countries` operation"
        announce_error(message, result)
        return
      end

      result = importer.fetch_all_unit_rates_for_properties(properties)

      if result.success?
        all_unit_rates = result.value
      else
        message = "Failed to perform the `#fetch_rates_for_properties` operation"
        announce_error(message, result)
        return
      end

      properties.each do |property|
        synchronisation.start(property.internal_id) do
          Concierge.context.disable!

          unit_rates = find_rates(property.internal_id, all_unit_rates)
          fetch_details_and_build_property(property, unit_rates)
        end
      end

      synchronisation.finish!
    end

    def fetch_details_and_build_property(property, rates)
      result = importer.fetch_detailed_property(property.internal_id)

      if result.success?
        detailed_property = result.value

        roomorama_property = ::SAW::Mappers::RoomoramaProperty.build(
          property,
          detailed_property,
          rates
        )

        Result.new(roomorama_property)
      else
        message = "Failed to perform the `#fetch_detailed_property` operation"
        announce_error(message, result)
        result
      end
    end

    private

    def importer
      @properties ||= ::SAW::Importer.new(credentials)
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
      all_unit_rates.find { |rate| rate.id == property_id.to_s }
    end
  end
end

Concierge::Announcer.on("metadata.SAW") do |host|
  Workers::Suppliers::SAW.new(host).perform
end
