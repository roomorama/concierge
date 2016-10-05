require "spec_helper"
require_relative "../shared/cancel"

RSpec.describe API::Controllers::Ciirus::Cancel do

  it_behaves_like 'cancel action' do
    let(:success_cases) do
      [
        { params: {reference_number: '5486789', inquiry_id: '125'}, cancelled_reference_number: '5486789' },
        { params: {reference_number: '2154254', inquiry_id: '128'}, cancelled_reference_number: '2154254' },
      ]
    end

    let(:error_cases) do
      [
        { params: {reference_number: '658794', inquiry_id: '392'}, error: 'Could not cancel with remote supplier' },
        { params: {reference_number: '245784', inquiry_id: '399'}, error: 'Already cancelled' }
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
