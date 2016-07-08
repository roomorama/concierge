module Ciirus
  module Mappers
    class Quote
      class << self
        # Maps hash representation of Ciirus API GetProperties response
        # to Quotation
        def build(params, hash)
          quotation = ::Quotation.new(
            property_id: params[:property_id],
            check_in:    params[:check_in].to_s,
            check_out:   params[:check_out].to_s,
            guests:      params[:guests],
            available:   available?(hash)
          )
          if quotation.available
            quotation.currency = parse_currency(hash)
            quotation.total = parse_total(hash)
          end
          quotation
        end

        private

        def parse_total(hash)
          hash.get('get_properties_response.get_properties_result.property_details.quote_including_tax')
        end

        def parse_currency(hash)
          hash.get('get_properties_response.get_properties_result.property_details.currency_code')
        end

        def available?(hash)
          error_msg = hash.get('get_properties_response.get_properties_result.property_details.error_msg')
          error_msg != Ciirus::Commands::QuoteFetcher::EMPTY_ERROR_MESSAGE
        end
      end
    end
  end
end
