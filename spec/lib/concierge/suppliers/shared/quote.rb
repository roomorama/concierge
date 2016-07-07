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
RSpec.shared_examples "supplier quote method" do

  context "when successful" do
    context "and available" do
      let(:quotation_result) { supplier_client.quote(success_params) }
      it "returns the wrapped quotation" do
        expect(quotation_result).to be_success

        quotation = quotation_result.value
        expect(quotation).to be_a Quotation
        expect(quotation.total > 0).to be_truthy
      end
    end
    context "and unavailable" do
      it "returns the result wrapping quotation" do
        unavailable_params_list.each do |params|
          quotation_result = supplier_client.quote(params)
          expect(quotation_result).to be_success

          quotation = quotation_result.value
          expect(quotation).to be_a Quotation
          expect(quotation.available).to be false
        end
      end
    end
  end

  context "when errors occur" do
    it "returns the error result" do
      error_params_list.each do |params|
        quotation_result = supplier_client.quote(params)
        expect(quotation_result).not_to be_success
        expect(quotation_result.error).to_not be_nil
      end
    end
  end
end

