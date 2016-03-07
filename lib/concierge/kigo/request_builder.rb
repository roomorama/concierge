module Kigo

  # +Kigo::RequestBuilder+
  #
  # This class is responsible for building the request payload to be sent to Kigo's
  # API, for different calls. It can be extended for usage with the Legacy API
  # due to the similarity of both interfaces.
  #
  # Usage
  #
  #   builder = Kigo::RequestBuilder.new
  #   builder.compute_pricing(params)
  #   # => #<Result error=nil value={ "PROP_ID" => 123, ... }>
  class RequestBuilder

    # Builds the required request parameters for a +computePricing+ Kigo API call.
    # Property identifiers are numerical in Kigo, and they must be sent as numbers.
    # Sending identifiers as strings produces an error.
    #
    # Returns a +Result+ instance encapsulating the operation. Fails with code
    # +invalid_property_id+ if the ID cannot be converted to an integer.
    def compute_pricing(params)
      property_id_conversion = to_integer(params[:property_id], :invalid_property_id)

      if property_id_conversion.success?
        Result.new({
          "PROP_ID"        => property_id_conversion.value,
          "RES_CHECK_IN"   => params[:check_in],
          "RES_CHECK_OUT"  => params[:check_out],
          "RES_N_ADULTS"   => params[:guests].to_i,
          "RES_N_CHILDREN" => 0
        })
      else
        property_id_conversion
      end
    end

    private

    def to_integer(str, error_code)
      Result.new(Integer(str))
    rescue ArgumentError => err
      Result.error(error_code, err.message)
    end

  end

end
