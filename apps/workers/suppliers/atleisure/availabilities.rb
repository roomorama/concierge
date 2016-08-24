module Workers
  module Suppliers
    module AtLeisure
      # +Workers::Suppliers::AtLeisure::Calendar+
      #
      # Performs properties availabilities synchronisation with supplier
      class Calendar
        BATCH_SIZE = 50

        attr_reader :synchronisation, :host

        def initialize(host)
          @host            = host
          @synchronisation = Workers::CalendarSynchronisation.new(host)
        end

        def perform
          identifiers = all_identifiers

          identifiers.each_slice(BATCH_SIZE) do |ids|
            result = synchronisation.new_context { importer.fetch_availabilities(ids) }
            if result.success?
              availabilities = result.value
              availabilities.each do |availability|
                property_id = availability['HouseCode']
                synchronisation.start(property_id) do
                  next availability_error(availability) unless valid_availability?(availability)

                  mapper.build(availability)
                end
              end
            else
              message = "Failed to perform the `#fetch_availabilities` operation, with properties: `#{ids}`"
              announce_error(message, result)
            end
          end
          synchronisation.finish!
        end

        private

        def availability_error(availability)
          property_id = availability['HouseCode']
          error_message = availability['error']
          message = "Error during fetching availabilities for property `#{property_id}`: `#{error_message}`"
          augment_context_error(message)

          Result.error(:availability_error)
        end

        def valid_availability?(availability)
          availability['error'].nil?
        end

        def all_identifiers
          PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
        end

        def mapper
          @mapper ||= ::AtLeisure::Mappers::Calendar.new
        end

        def importer
          @importer ||= ::AtLeisure::Importer.new(credentials)
        end

        def credentials
          Concierge::Credentials.for(::AtLeisure::Client::SUPPLIER_NAME)
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
            supplier:    ::AtLeisure::Client::SUPPLIER_NAME,
            code:        result.error.code,
            context:     Concierge.context.to_h,
            happened_at: Time.now
          })
        end
      end
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('availabilities.AtLeisure') do |host|
  Workers::Suppliers::Atleisure::Calendar.new(host).perform
end
