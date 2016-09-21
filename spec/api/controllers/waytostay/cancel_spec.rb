require 'spec_helper'
require_relative "../shared/cancel"

RSpec.describe API::Controllers::Waytostay::Cancel do
  let(:params) { { reference_number: "A123", inquiry_id: "123" } }

  it_behaves_like "cancel action" do
    let(:success_cases) {
      [
        { params: {reference_number: "A023", inquiry_id: "392"}, cancelled_reference_number: "XYZ" },
        { params: {reference_number: "A024", inquiry_id: "398"}, cancelled_reference_number: "ASD" },
      ]
    }
    let(:error_cases) {
      [
        { params: {reference_number: "A123", inquiry_id: "320"}, error: {"cancellation" => "Could not cancel with remote supplier"} },
        { params: {reference_number: "A124", inquiry_id: "328"}, error: {"cancellation" => "Already cancelled"} },
      ]
    }

    before do
      allow_any_instance_of(Waytostay::Client).to receive(:cancel) do |instance, par|
        result = nil
        error_cases.each do |kase|
          if par.reference_number == kase[:params][:reference_number]
            result = Result.error(:already_cancelled, kase[:error])
            break
          end
        end
        success_cases.each do |kase|
          if par.reference_number == kase[:params][:reference_number]
            result = Result.new(kase[:cancelled_reference_number])
            break
          end
        end
        result
      end
    end
  end

end
