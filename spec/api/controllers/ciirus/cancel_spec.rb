require "spec_helper"
require_relative "../shared/cancel"

RSpec.describe API::Controllers::Ciirus::Cancel do

  it_behaves_like 'cancel action' do
    let(:success_cases) do
      [
        { params: {reservation_id: '5486789'}, cancelled_reservation_id: '5486789' },
        { params: {reservation_id: '2154254'}, cancelled_reservation_id: '2154254' },
      ]
    end

    let(:error_cases) do
      [
        { params: {reservation_id: '658794'}, error: {'cancellation' => 'Could not cancel with remote supplier'} },
        { params: {reservation_id: '245784'}, error: {'cancellation' => 'Already cancelled'} }
      ]
    end
  end

  before do
    allow_any_instance_of(Ciirus::Client).to receive(:cancel) do |instance, par|
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