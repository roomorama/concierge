module SAW
  module Mappers
    # +SAW::Mappers::Quotation+
    #
    # This class is responsible for building a +Quotation+ object
    class Quotation
      class << self
        # Builds a quotation
        #
        # Arguments:
        #
        #   * +params+ [Hash] quotation request parameters
        #   * +safe_hash+ [Concierge::SafeAccessHash] result hash with price
        #
        # Returns [Quotation]
        def build(params, safe_hash)
          requested_unit = find_requested_unit(safe_hash, params[:unit_id])

          if requested_unit
            ::Quotation.new(
              property_id: params[:property_id],
              unit_id:     params[:unit_id],
              check_in:    params[:check_in].to_s,
              check_out:   params[:check_out].to_s,
              guests:      params[:guests],
              currency:    parse_currency(safe_hash),
              total:       parse_price(requested_unit),
              available:   parse_availability(requested_unit)
            )
          else
            build_unavailable(params)
          end
        end

        private
        # Builds unavailable quotation.
        # Used in cases when rates information for unit is not available.
        #
        # Arguments:
        #
        #   * +params+ [Hash] parameters
        #
        # Returns [Quotation]
        def build_unavailable(params)
          ::Quotation.new(
            property_id: params[:property_id],
            unit_id:     params[:unit_id],
            check_in:    params[:check_in].to_s,
            check_out:   params[:check_out].to_s,
            guests:      params[:guests],
            available:   false
          )
        end

        def units_hash(hash)
          hash.get("apartments.accommodation_type.property_accommodation")
        end

        def find_requested_unit(safe_hash, id)
          units = units_hash(safe_hash)
          requested_unit_hash = Array(units).find { |u| u["@id"] == id }

          return nil unless requested_unit_hash
          Concierge::SafeAccessHash.new(requested_unit_hash)
        end

        def parse_currency(hash)
          hash.get("currency_code")
        end

        def parse_price(hash)
          price = hash.get("price_detail.net.total_price.price")
          BigDecimal.new(price)
        end

        # Parses flags for availability.
        # From SAW documentation (http://staging.servicedapartmentsworldwide.net/xml/propertyrateshtm.aspx):
        #
        # <flag_bookable_property_accommodation> 'Y' or 'N'
        #   (Y = Bookable Property Accommodation, N = Not Bookable Property Accommodation)
        #
        # <flag_no_allocation> 'Y' or 'N'
        #   (Y = Property Accommodation not available now, N = Property Accommodation is available)
        #   [No allocation property can booked as request but it will be confirmed later by property]
        #
        # <flag_fair_warning> 'Y' or 'N'
        #   (Y = Fair warning, N = Not Fair warning)
        #   [Fair warning property accommodation can't booked]
        #
        def parse_availability(hash)
          bookable = hash.get("flag_bookable_property_accommodation")
          no_allocation = hash.get("status.flag_no_allocation")
          fair_warning = hash.get("status.flag_fair_warning")
          bookable == "Y" && no_allocation == "N" && fair_warning == "N"
        end
      end
    end
  end
end
