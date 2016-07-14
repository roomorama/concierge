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
      
      result = importer.fetch_properties_by_countries(countries)
      
      if result.success?
        properties = result.value
      else
        message = "Failed to perform the `#fetch_properties_by_countries` operation"
        announce_error(message, result)
        return
      end

      properties.each do |property|
        synchronisation.start(property.internal_id) do
          Concierge.context.disable!

          result = importer.fetch_detailed_property(property.internal_id)

          if result.success?
            detailed_property = result.value
          else
            message = "Failed to perform the `#fetch_detailed_property` operation"
            announce_error(message, result)
          end
          
          availability_calendar = ::SAW::Mappers::AvailabilityCalendar.build

          roomorama_property = ::SAW::Mappers::RoomoramaProperty.build(
            property,
            detailed_property,
            availability_calendar
          )
          
          Result.new(roomorama_property)
        end
      end

      synchronisation.finish!
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
  end
end

Concierge::Announcer.on("metadata.SAW") do |host|
  Workers::Suppliers::SAW.new(host).perform
end
