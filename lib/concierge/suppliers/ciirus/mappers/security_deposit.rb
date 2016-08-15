module Ciirus
  module Mappers
    class SecurityDeposit

      # CiiRUS code for Security Deposit extra
      SECURITY_DEPOSIT_CODE = 'SD'

      # Maps hash representation of Ciirus API GetExtras response
      # to +Ciirus::Entities::Extra+ for security deposit extra.
      # If there is no security deposit extra returns nil.
      def build(hash)
        extras_result = hash.get('get_extras_response.get_extras_result')

        security_deposit_hash = find_security_deposit_extra(extras_result)

        if security_deposit_hash
          map_security_deposit_extra(security_deposit_hash)
        end
      end

      private

      def find_security_deposit_extra(extras_result)
        if extras_result[:row_count].to_i > 0
          extras = Array(extras_result.get('extras.property_extras'))
          extras.detect { |e| security_deposit?(e) }
        end
      end

      def security_deposit?(extra)
        extra[:item_code] == SECURITY_DEPOSIT_CODE
      end

      def map_security_deposit_extra(sd_hash)
        attrs = {
          property_id:      sd_hash[:property_id],
          item_code:        sd_hash[:item_code],
          item_description: sd_hash[:item_description],
          flat_fee:         sd_hash[:flat_fee],
          flat_fee_amount:  sd_hash[:flat_fee_amount].to_f,
          daily_fee:        sd_hash[:daily_fee],
          daily_fee_amount: sd_hash[:daily_fee_amount].to_f,
          percentage_fee:   sd_hash[:percentage_fee],
          percentage:       sd_hash[:percentage].to_f,
          mandatory:        sd_hash[:mandatory],
          minimum_charge:   sd_hash[:minimum_charge].to_f
        }

        Ciirus::Entities::Extra.new(attrs)
      end
    end
  end
end
