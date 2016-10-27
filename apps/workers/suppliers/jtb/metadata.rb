module Workers::Suppliers::JTB
  # +Workers::Suppliers::JTB::Metadata+
  #
  # Performs properties synchronisation with supplier
  class Metadata
    PERIOD_SYNC = 365

    attr_reader :property_synchronisation, :calendar_synchronisation, :host

    SKIPABLE_ERROR_CODES = [
      :empty_images,
      :unknown_nightly_rate
    ]

    def initialize(host)
      @host            = host
      @property_synchronisation = Workers::PropertySynchronisation.new(host)
      @calendar_synchronisation = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      result = property_synchronisation.new_context do
        actualizer.actualize
      end

      if result.success?
        hotels = JTB::Repositories::HotelRepository.english_ryokans

        hotels.each do |hotel|
          property_id = hotel.jtb_hotel_code
          property_synchronisation.start(property_id) do
            result = mapper.build(hotel)

            if !result.success? && SKIPABLE_ERROR_CODES.include?(result.error.code)
              property_synchronisation.skip_property(property_id, result.error.code)
            else
              result
            end
          end

          # sync calendar if property synced
          property = fetch_property(property_id)
          sync_calendar(property) if property
        end
      else
        property_synchronisation.failed!
        message = 'Failed to perform full actualization of DB'
        announce_error(message, result)
      end

      calendar_synchronisation.finish!
      property_synchronisation.finish!
    end

    private

    def sync_calendar(property)
      calendar_synchronisation.start(property.identifier) do
        calendar_mapper(property).build
      end
    end

    def fetch_property(property_id)
      PropertyRepository.from_host(host).identified_by(property_id).first
    end

    def actualizer
      @actualizer ||= ::JTB::Sync::Actualizer.new(credentials)
    end

    def mapper
      @mapper ||= ::JTB::Mappers::RoomoramaProperty.new
    end

    def calendar_mapper(property)
      ::JTB::Mappers::Calendar.new(property)
    end

    def credentials
      Concierge::Credentials.for(JTB::Client::SUPPLIER_NAME)
    end

    def augment_context_error(message)
      message = {
        label: 'Synchronisation Failure',
        message: message,
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)
    end

    def announce_error(message, result)
      augment_context_error(message)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    JTB::Client::SUPPLIER_NAME,
        code:        result.error.code,
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('metadata.JTB') do |host, args|
  Workers::Suppliers::JTB::Metadata.new(host).perform
  Result.new({})
end
