module Avantio
  module Mappers
    class Services

      SPECIAL_SERVICES_SELECTOR = 'Features/ExtrasAndServices/SpecialServices'
      COMMON_SERVICES_SELECTOR = 'Features/ExtrasAndServices/CommonServices'

      PETS_SERVICE_SELECTOR = 'SpecialService[Code[text() = "9"]]'
      DEPOSIT_SERVICE_SELECTOR = 'SpecialService[Code[text() = "11"]]'
      CLEANING_SERVICE_SELECTOR = 'CommonService[Code[text() = "10"]]'
      INTERNET_SERVICE_SELECTOR = 'CommonService[Code[text() = "8"]]'
      BED_LINEN_SERVICE_SELECTOR = 'SpecialService[Code[text() = "6"]]'
      TOWELS_SERVICE_SELECTOR = 'SpecialService[Code[text() = "7"]]'
      PARKING_SERVICE_SELECTOR = 'SpecialService[Code[text() = "3"]]'
      AIRCONDITIONING_SERVICE_SELECTOR = 'SpecialService[Code[text() = "2"]]'

      SECURITY_DEPOSIT_TYPES = {
        'DINERO'            => 'cash',
        'TARJETA_RETENCION' => 'credit_card_auth',
        'TARJETA_COBRO'     => 'credit_card_auth',
        'TARJETA_GARANTIA'  => 'credit_card_auth',
        'CHEQUE_VACANCES'   => 'check',
        'CHEQUE'            => 'check'
      }

      attr_reader :common_services_raw, :special_services_raw

      def build(accommodation_raw)
        @common_services_raw = accommodation_raw.at_xpath(COMMON_SERVICES_SELECTOR)
        @special_services_raw = accommodation_raw.at_xpath(SPECIAL_SERVICES_SELECTOR)
        attrs = {}
        pets_allowed!(attrs)
        cleaning_service!(attrs)
        security_deposit!(attrs)
        bed_linen_service!(attrs)
        towels_service!(attrs)
        parking_service!(attrs)
        airconditioning_service!(attrs)
        internet_service!(attrs)

        attrs
      end

      private

      def pets_allowed!(attrs)
        service_raw = special_services_raw&.at_xpath(PETS_SERVICE_SELECTOR)
        if service_raw &&
             all_year_around?(service_raw) &&
             included_in_price(service_raw) == 'true'
          # There also possible value "peso-menor-que" (WEIGHT-LESS-THAN)
          # we ignore this case
          attrs[:pets_allowed] = case service_raw.at_xpath('Allowed')&.text.to_s
                                 when 'si' then true
                                 when 'no' then false
                                 end
        end
      end

      def security_deposit!(attrs)
        service_raw = special_services_raw&.at_xpath(DEPOSIT_SERVICE_SELECTOR)
        if service_raw &&
             all_year_around?(service_raw) &&
             included_in_price(service_raw) == 'false' &&
             required?(service_raw)
          amount = service_price(service_raw)
          type = service_raw&.at_xpath('PaymentMethod')&.text&.to_s
          unless amount == 0
            attrs[:security_deposit_amount] = amount
            attrs[:security_deposit_type] = SECURITY_DEPOSIT_TYPES.fetch(type, 'unknown')
            attrs[:security_deposit_currency_code] = service_raw&.at_xpath('AdditionalPrice/Currency')&.text
          end
        end
      end

      def cleaning_service!(attrs)
        service_raw = common_services_raw&.at_xpath(CLEANING_SERVICE_SELECTOR)
        if service_raw && all_year_around?(service_raw)
          amount = service_price(service_raw)
          if amount == 0
            attrs[:free_cleaning] = true
          elsif included_in_price(service_raw) == 'false'
            attrs[:services_cleaning] = true
            attrs[:services_cleaning_rate] = amount
            attrs[:services_cleaning_required] = required?(service_raw)
          end
        end
      end

      def bed_linen_service!(attrs)
        service_raw = special_services_raw&.at_xpath(BED_LINEN_SERVICE_SELECTOR)
        if service_raw && all_year_around?(service_raw)
          attrs[:bed_linen] = provided?(service_raw) && required_or_included?(service_raw)
        end
      end

      def towels_service!(attrs)
        service_raw = special_services_raw&.at_xpath(BED_LINEN_SERVICE_SELECTOR)
        if service_raw && all_year_around?(service_raw)
          attrs[:towels] = provided?(service_raw) && required_or_included?(service_raw)
        end
      end

      def parking_service!(attrs)
        service_raw = special_services_raw&.at_xpath(PARKING_SERVICE_SELECTOR)
        if service_raw && all_year_around?(service_raw)
          attrs[:parking] = required_or_included?(service_raw)
        end
      end

      def airconditioning_service!(attrs)
        service_raw = special_services_raw&.at_xpath(AIRCONDITIONING_SERVICE_SELECTOR)
        if service_raw && all_year_around?(service_raw)
          attrs[:airconditioning] = required_or_included?(service_raw)
        end
      end

      def internet_service!(attrs)
        service_raw = common_services_raw&.at_xpath(INTERNET_SERVICE_SELECTOR)
        if service_raw && all_year_around?(service_raw)
          attrs[:internet] = required_or_included?(service_raw)
        end
      end

      # Actual only for towels and bed_linen services
      def provided?(service_raw)
        service_raw.at_xpath('Type')&.text.to_s == 'Suministrada'
      end

      def service_price(service_raw)
        service_raw.at_xpath('AdditionalPrice/Quantity')&.text&.to_f
      end

      def required_or_included?(service_raw)
        required?(service_raw) || included_in_price(service_raw) == 'true'
      end

      def required?(service_raw)
        service_raw.at_xpath('Application')&.text.to_s == 'OBLIGATORIO-SIEMPRE'
      end

      def included_in_price(service_raw)
        service_raw.at_xpath('IncludedInPrice')&.text.to_s
      end

      def all_year_around?(service_raw)
        start_day = service_raw.at_xpath('Season/StartDay')&.text
        start_month = service_raw.at_xpath('Season/StartMonth')&.text
        final_day = service_raw.at_xpath('Season/FinalDay')&.text
        final_month = service_raw.at_xpath('Season/FinalMonth')&.text

        start_day == '1' && start_month == '1' && final_day == '31' && final_month == '12'
      end
    end
  end
end
