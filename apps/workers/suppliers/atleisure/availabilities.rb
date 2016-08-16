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
          today = Date.today
          identifiers = all_identifiers

          identifiers.each_slice(BATCH_SIZE) do |ids|
            result = importer.fetch_availabilities(ids)
            if result.success?
              availabilities = result.value
              property_id = availabilities['HouseCode']
              synchronisation.start(property_id) do
                stays = []
                availabilities.map do |availability|
                  if validator(availability, today).valid?
                    stays << to_stay(availability)
                  end
                end
                build_calendar(property_id, stays)
              end
            else
              message = "Failed to perform the `#fetch_availabilities` operation, with properties: `#{ids}`"
              augment_context_error(message)
            end
          end
          synchronisation.finish!
        end

        private

        def to_stay(availability)
          Roomorama::Calendar::Stay.new({
            checkin:    availability['ArrivalDate'],
            checkout:   availability['DepartureDate'],
            price:      availability['Price'].to_f,
            available:  true
          })
        end

        def build_calendar(property_id, stays)
          calendar = Roomorama::Calendar.new(property_id).tap do |c|
            entries = StaysMapper.new(stays).map
            entries.each { |entry| c.add(entry) }
          end

          Result.new(calendar)
        end


        def all_identifiers
          PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
        end

        def validator(availability, today)
          ::AtLeisure::AvailabilityValidator.new(availability, today)
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
