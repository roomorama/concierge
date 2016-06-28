module Ciirus
  module Mappers
    class Quote
      class << self
        # Maps hash representation of Ciirus API IsPropertyAvailable response
        # to bool
        def build(params, hash)
          ::Quotation.new(
              property_id: params[:property_id],
              check_in:    params[:check_in].to_s,
              check_out:   params[:check_out].to_s,
              guests:      params[:guests],
              currency:    parse_currency(hash),
              available:   true,
              total:       parse_total(hash)
          )
        end

        private

        def parse_total(hash)
          hash.get('get_properties_response.quote_including_tax')
        end

        def parse_currency(hash)
          hash.get('get_properties_response.currency_code')
        end
      end
    end
  end
end
