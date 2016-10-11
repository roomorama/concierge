module Workers::Suppliers::JTB
  # +Workers::Suppliers::JTB::Metadata+
  #
  # Performs properties synchronisation with supplier
  class Metadata
    PERIOD_SYNC = 365

    attr_reader :synchronisation, :host, :files_fetcher, :db_importer

    SKIPABLE_ERROR_CODES = [
      :empty_images,
      :unknown_nightly_rate
    ]

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
      @files_fetcher = JTB::FilesFetcher.new(credentials)
      @db_importer = JTB::DBImporter.new(tmp_path)
    end

    def perform
      result = synchronisation.new_context do
        actualizer.actualize
      end

      if result.success?

        hotels = JTB::Repositories::HotelRepository.english_ryokans

        hotels.each do |hotel|
          synchronisation.start(hotel.jtb_hotel_code) do
            result = mapper.build(hotel)

            if !result.success? && SKIPABLE_ERROR_CODES.include?(result.error.code)
              synchronisation.skip_property(hotel.jtb_hotel_code, result.error.code)
            else
              result
            end
          end
        end
        synchronisation.finish!
      else
        synchronisation.failed!
        message = 'Failed to perform full actualization of DB'
        announce_error(message, result)
      end
    end

    private

    def actualizer
      @actualizer ||= ::JTB::Sync::Actualizer.new(credentials)
    end

    def mapper
      @mapper ||= ::JTB::Mappers::RoomoramaProperty.new
    end

    def credentials
      Concierge::Credentials.for(JTB::Client::SUPPLIER_NAME)
    end

    def tmp_path
      credentials.sftp['tmp_path']
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
