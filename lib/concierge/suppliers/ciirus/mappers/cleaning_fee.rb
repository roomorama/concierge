module Ciirus
  module Mappers
    class CleaningFee
      # Maps hash representation of Ciirus API GetCleaningFee response
      # to Ciirus::Entities::CleaningFee
      def build(hash)
        cleaning_fee = hash.get('get_cleaning_fee_response.get_cleaning_fee_result')
        Ciirus::Entities::CleaningFee.new(
          cleaning_fee[:charge_cleaning_fee],
          Float(cleaning_fee[:cleaning_fee_amount])
        )
      end
    end
  end
end