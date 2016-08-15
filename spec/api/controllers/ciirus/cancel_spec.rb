require "spec_helper"
require_relative "../shared/cancel"

RSpec.describe API::Controllers::Ciirus::Cancel do

  it_behaves_like 'cancel action' do
    let(:success_cases) do
      [
        { params: {reference_number: '5486789'}, cancelled_reference_number: '5486789' },
        { params: {reference_number: '2154254'}, cancelled_reference_number: '2154254' },
      ]
    end

    let(:error_cases) do
      [
        { params: {reference_number: '658794'}, error: {'cancellation' => 'Could not cancel with remote supplier'} },
        { params: {reference_number: '245784'}, error: {'cancellation' => 'Already cancelled'} }
      ]
    end
  end

  before do
    allow_any_instance_of(Ciirus::Client).to receive(:cancel) do |instance, par|
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