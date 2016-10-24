require "spec_helper"
require_relative "../shared/cancel"

RSpec.describe API::Controllers::JTB::Cancel do
  include Support::Factories

  let(:reference_number) { 'reservation_id|rate_plan_id' }
  before do
    create_reservation({ supplier: JTB::Client::SUPPLIER_NAME,
                         reference_number: reference_number })
  end

  it_behaves_like 'cancel action' do
    let(:success_cases) do
      [
        { params: {reference_number: 'reservation_id1|rate_plan_id', inquiry_id: '125'}, cancelled_reference_number: 'reservation_id1|rate_plan_id' },
        { params: {reference_number: 'reservation_id2|rate_plan_id', inquiry_id: '128'}, cancelled_reference_number: 'reservation_id2|rate_plan_id' },
      ]
    end

    let(:error_cases) do
      [
        { params: {reference_number: 'reservation_id3|rate_plan_id', inquiry_id: '392'}, error: 'Could not cancel with remote supplier' },
        { params: {reference_number: 'reservation_id4|rate_plan_id', inquiry_id: '399'}, error: 'Already cancelled' }
      ]
    end
  end

  before do
    allow_any_instance_of(JTB::Client).to receive(:cancel) do |instance, par|
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
