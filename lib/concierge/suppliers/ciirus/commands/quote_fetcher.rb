module Ciirus
  module Commands
    # +Ciirus::Commands::QuoteFetcher+
    #
    # This class is responsible for wrapping the logic related to making a price
    # quotation to Ciirus, parsing the response, and building the +Quotation+ object
    # with the data returned from their API.
    #
    # Usage
    #
    #   command = Ciirus::Commands::QuoteFetcher.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value # Quotation instance
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +Quotation+.
    class QuoteFetcher < BaseCommand
      ROOMORAMA_DATE_FORMAT = "%Y-%m-%d"
      CIIRUS_DATE_FORMAT = "%d %b %Y"

      def call(params)
        filter_options = Ciirus::FilterOptions.new(property_id: params[:property_id])
        search_options = Ciirus::SearchOptions.new(quote: true)
        special_options = Ciirus::SpecialOptions.new
        arrive_date = convert_date(params[:check_in])
        depart_date = convert_date(params[:check_out])
        message = xml_builder.properties(filter_options, search_options,
                                         special_options, arrive_date,
                                         depart_date)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          if valid_result?(result_hash)
            quotation = Ciirus::Mappers::Quote.build(params, result_hash)
            Result.new(quotation)
          else
            error_result(result_hash)
          end
        end
      end

      protected

      def operation_name
        :get_properties
      end

      private

      # Converts date string to Ciirus expected format
      def convert_date(date)
        Date.strptime(date, ROOMORAMA_DATE_FORMAT).strftime(CIIRUS_DATE_FORMAT)
      end
    end
  end
end
