module Ciirus
  module Commands
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
          result_hash = response_parser.to_hash(result.value)
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
        :GetProperties
      end

      private

      # Converts date string to Ciirus expected format
      def convert_date(date)
        Date.strptime(date, ROOMORAMA_DATE_FORMAT).strftime(CIIRUS_DATE_FORMAT)
      end
    end
  end
end
