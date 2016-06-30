# Shared example for supplier client's book method.
#
# Some context variables required:
#
#   supplier_client:     An instance of the client being tested. `#quote` will be called on this
#
#   success_params:      Arguments for `#quote` in the happy case.
#                        Assertions will be made on `supplier_client.quote(success_params)`
#
#   successful_code:     The returned successful reservation reference, asserted against the value returned from `book`
#
#   error_params_list:   A collection of arguments for `#quote` when some error occurs.
#                        For each item p, assertions will be made on `supplier_client.quote(p)`
#
RSpec.shared_examples "supplier book method" do

  context "when successful" do
    it 'returns reservation' do
      reservation_result = supplier_client.book(success_params)
      expect(reservation_result).to be_success
      reservation = reservation_result.value
      expect(reservation).to be_a Reservation
      expect(reservation).to be_successful

      expect(reservation.code).to be_a String
      expect(reservation.code).to eq successful_code
    end
  end

  context "when errors occur" do
    it "fails with generic error" do
      error_params_list.each do |params|
        reservation_result = supplier_client.book(params)
        expect(reservation_result).to_not be_success
        expect(reservation_result.error).to_not be_nil
      end
    end
  end
end

