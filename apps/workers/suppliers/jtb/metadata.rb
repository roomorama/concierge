module Workers::Suppliers::JTB
  # +Workers::Suppliers::JTB::Metadata+
  #
  # Performs properties synchronisation with supplier
  class Metadata
    attr_reader :synchronisation, :host, :files_fetcher, :db_importer

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
      @files_fetcher = JTB::FilesFetcher.new(credentials)
      @db_importer = JTB::DBImporter.new(tmp_path)
    end

    def perform
      begin
        synchronisation.new_context do
          files_fetcher.fetch_files
        end

        db_importer.import

        hotels = JTB::HotelRepository.english_ryokans

        # sync_here
        hotels.each do |hotel|
          pictures = JTB::PictureRepository.hotel_english_images(hotel.city_code, hotel.hotel_code)
          synchronisation.start do
            mapper.build(hotel, pictures)
          end
        end
      ensure
        db_importer.cleanup
        files_fetcher.cleanup
      end


      # if result.success?
      #   properties = result.value
      #   properties.each do |property|
      #     property_id = property.property_id
      #     if validator(property).valid?
      #       permissions = synchronisation.new_context(property_id) do
      #         fetch_permissions(property_id)
      #       end
      #       next unless permissions.success?
      #
      #       unless permissions_validator(permissions.value).valid?
      #         synchronisation.skip_property(property_id, 'Invalid permissions')
      #         next
      #       end
      #
      #       # Rates are needed for a property. Skip (and purge) properties that
      #       # has no rates or has error when retrieving rates.
      #       result = fetch_rates(property_id)
      #       next unless result.success?
      #
      #       rates  = filter_rates(result.value)
      #       if rates.empty?
      #         synchronisation.skip_property(property_id, 'Empty valid rates list')
      #         next
      #       end
      #
      #       result = fetch_images(property_id)
      #       next unless result.success?
      #       images = result.value
      #
      #       result = fetch_description(property_id)
      #       next unless result.success?
      #       description = result.value
      #       if description.to_s.empty?
      #         synchronisation.skip_property(property_id, 'Empty description')
      #         next
      #       end
      #
      #       synchronisation.start(property_id) do
      #
      #         result = fetch_security_deposit(property_id)
      #         security_deposit = result.success? ? result.value : nil
      #
      #         roomorama_property = mapper.build(property, images, rates, description, security_deposit)
      #         Result.new(roomorama_property)
      #       end
      #     else
      #       synchronisation.skip_property(property_id, 'Invalid property')
      #     end
      #   end
      #   synchronisation.finish!
      # else
      #   synchronisation.failed!
      #   message = 'Failed to perform the `#fetch_properties` operation'
      #   announce_error(message, result)
      # end
    end

    private

    def rate_validator(rate, today)
      Ciirus::Validators::RateValidator.new(rate, today)
    end

    def filter_rates(rates)
      today = Date.today
      rates.select { |r| rate_validator(r, today).valid? }
    end

    def report_error(message)
      yield.tap do |result|
        augment_context_error(message) unless result.success?
      end
    end

    def fetch_images(property_id)
      importer.fetch_images(property_id).tap do |result|
        unless result.success?
          if ignorable_images_error?(result.error)
            synchronisation.skip_property(property_id, "Ignorable images error: #{result.error.data}")
          else
            message = "Failed to fetch images for property `#{property_id}`"
            announce_error(message, result)
          end
        end
      end
    end

    def fetch_description(property_id)
      importer.fetch_description(property_id).tap do |result|
        message = "Failed to fetch description for property `#{property_id}`"
        announce_error(message, result) unless result.success?
      end
    end

    def fetch_rates(property_id)
      importer.fetch_rates(property_id).tap do |result|
        unless result.success?
          if ignorable_rates_error?(result.error)
            synchronisation.skip_property(property_id, "Ignorable rates error: #{result.error.data}")
          else
            message = "Failed to fetch rates for property `#{property_id}`"
            announce_error(message, result)
          end
        end
      end
    end

    def fetch_permissions(property_id)
      importer.fetch_permissions(property_id).tap do |result|
        message = "Failed to fetch permissions for property `#{property_id}`"
        announce_error(message, result) unless result.success?
      end
    end

    def fetch_security_deposit(property_id)
      message = "Failed to fetch security deposit info for property `#{property_id}`. " \
            "But continue to sync the property as well as security deposit is optional information."
      report_error(message) do
        importer.fetch_security_deposit(property_id)
      end
    end

    def mapper
      @mapper ||= ::JTB::Mappers::RoomoramaProperty.new
    end

    def importer
      @importer ||= ::Ciirus::Importer.new(credentials)
    end

    def validator(property)
      Ciirus::Validators::PropertyValidator.new(property)
    end


    def permissions_validator(permissions)
      Ciirus::Validators::PermissionsValidator.new(permissions)
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
        supplier:    Ciirus::Client::SUPPLIER_NAME,
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
