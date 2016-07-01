require "spec_helper"

RSpec.shared_examples "cancellation action" do

  subject { call(controller, params) }

  context "when supplier return +Result+ error, without data" do

    it "returns a generic error message and create an ExternalError" do
      expect(generic_error_params_list).to_not be_empty
      generic_error_params_list.each do |params|
        expect {
          expect(subject.status).to eq 503
          expect(subject.body["status"]).to eq "error"
          expect(subject.body["errors"]).to eq({ "cancellation" => "Could not cancell with remote supplier" })
        }.to change { ExternalErrorRepository.count }.by 1
      end
    end
  end

  context "when supplier returns a successful +Result+" do

    it "returns the cancelled reservation id" do
      expect(success_params_list).to_not be_empty
      success_cases.each do |kase|
        params = kase.params
        expect(subject.status).to eq 200
        expect(response.body["status"]).to eq "ok"
        expect(response.body["cancelled_booking_id"]).to eq kase.cancelled_booking_id
      end
    end
  end
end

private

def call(controller, params)
  response = controller.call(params)

  # Wrap Rack data structure for an HTTP response
  Support::HTTPStubbing::ResponseWrapper.new(
    response[0],
    response[1],
    JSON.parse(response[2].first)
  )
end
