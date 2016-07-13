module Ciirus
  module Commands
    #  +Ciirus::ReservationsFetcher+
    #
    # This class is responsible for fetching property reservations
    # from Ciirus API, parsing the response and building the result.
    #
    # Usage
    #
    #   result = Ciirus::Commands::ReservationsFetcher.new(credentials).fetch(property_id)
    #   if result.success?
    #     result.value
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the collection of +Ciirus::Entities::Reservation+.
    class ReservationsFetcher < BaseCommand

      def call(property_id)
        message = xml_builder.reservations(property_id)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          property_rates = build_reservations(result_hash)
          Result.new(property_rates)
        else
          result
        end
      end

      protected

      def operation_name
        :get_reservations
      end

      private

      def mapper
        @mapper ||= Ciirus::Mappers::Reservation.new
      end

      def build_reservations(result_hash)
        reservations = result_hash.get(
          'get_reservations_response.get_reservations_result.reservations'
        )

        return [] unless reservations

        Array(reservations).map { |reservation| mapper.build(reservation) }
      end
    end
  end
end
