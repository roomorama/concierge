require 'spec_helper'
require_relative "../shared/cancel"

RSpec.describe API::Controllers::Waytostay::Cancel do
  let(:params) { { reservation_id: "A123" } }

  it_behaves_like "cancel action" do
    let(:success_cases) {
      [
        { params: {reservation_id: "A023"}, cancelled_reservation_id: "XYZ" },
        { params: {reservation_id: "A024"}, cancelled_reservation_id: "ASD" },
      ]
    }
    let(:error_cases) {
      [
        { params: {reservation_id: "A123"}, error: {"cancellation" => "Could not cancel with remote supplier"} },
        { params: {reservation_id: "A124"}, error: {"cancellation" => "Already cancelled"} },
      ]
    }

    before do
      allow_any_instance_of(Waytostay::Client).to receive(:cancel) do |instance, par|
        result = nil
        error_cases.each do |kase|
          if par.reservation_id == kase[:params][:reservation_id]
            result = Result.error(:already_cancelled, kase[:error])
            break
          end
        end
        success_cases.each do |kase|
          if par.reservation_id == kase[:params][:reservation_id]
            result = Result.new(kase[:cancelled_reservation_id])
            break
          end
        end
        result
      end
    end
  end

end
