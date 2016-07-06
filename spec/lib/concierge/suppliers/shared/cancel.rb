# Shared example for supplier client's quote method.
#
# Some context variables required:
#
#   supplier_client:     An instance of the client being tested. `#quote` will be called on this
#
#   success_params:      Arguments for `#quote` in the happy case.
#                        Assertions will be made on `supplier_client.quote(success_params)`
#
#   unavailable_params:  Arguments for `#quote` when the room is not available.
#                        Assertions will be made on `supplier_client.quote(unavailable_params)`
#
#   error_params_list:   A collection of arguments for `#quote` when some error occurs.
#                        For each item p, assertions will be made on `supplier_client.quote(p)`
#
RSpec.shared_examples "supplier cancel method" do

  context "when successful" do
    it "returns a +Result+ wrapping the reservation id" do
      result = supplier_client.cancel(success_params)
      expect(result).to be_success
      expect(result.value).to eq success_params[:reservation_id]
    end
  end

  context "when errors occur" do
    it "returns the erred quotation" do
      result = supplier_client.cancel(error_params)
      expect(result).to_not be_success
      expect(result.error).to_not be_nil
    end
  end
end

