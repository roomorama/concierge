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
            result = importer.fetch_availabilities(ids)
            if result.success?
              availabilities = result.value
              property_id = availabilities['HouseCode']
              synchronisation.start(property_id) { mapper.build(availabilities) }
            else
              message = "Failed to perform the `#fetch_availabilities` operation, with properties: `#{ids}`"
              augment_context_error(message)
            end
          end
          synchronisation.finish!
        end

        private

        def all_identifiers
          PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
        end

        def mapper
          @mapper ||= AtLeisure::Mappers::Calendar.new
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
      end
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('availabilities.AtLeisure') do |host|
  Workers::Suppliers::Atleisure::Calendar.new(host).perform
end
