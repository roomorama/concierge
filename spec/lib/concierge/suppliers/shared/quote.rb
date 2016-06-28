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
      let(:quotation) { supplier_client.quote(success_params) }
      it "returns the wrapped quotation" do
        expect(quotation).to be_a Quotation
        expect(quotation).to be_successful
        expect(quotation.errors).to be_nil
        expect(quotation.total > 0).to be_truthy
      end
    end
    context "and unavailable" do
      let(:quotation) { supplier_client.quote(unavailable_params) }
      it "returns the wrapped quotation" do
        expect(quotation).to be_a Quotation
        expect(quotation).to be_successful
        expect(quotation.errors).to be_nil
        expect(quotation.available).to be false
      end
      it "should not create an external error" do
        expect{ quotation }.to_not change{ ExternalErrorRepository.count }
      end
    end
  end

  context "when errors occur" do
    it "returns the erred quotation" do
      error_params_list.each do |params|
        expect{
          quotation = supplier_client.quote(params)
          expect(quotation).not_to be_successful
          expect(quotation.errors[:quote]).to eq "Could not quote price with remote supplier"
        }.to change{ ExternalErrorRepository.count }.by 1
      end
    end
  end
end

