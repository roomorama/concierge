require "spec_helper"

RSpec.shared_examples "cancel action" do

  context "when supplier return +Result+ error, without data" do

    before { expect(error_cases).to_not be_empty }

    it "returns a generic error message and create an ExternalError" do
      error_cases.each do |kase|
        expect {
          response = call(described_class.new, kase[:params].dup)
          expect(response.status).to eq 503
          expect(response.body["status"]).to eq "error"
          expect(response.body["errors"]).to eq kase[:error]
        }.to change { ExternalErrorRepository.count }.by 1
      end
    end
  end

  context "when supplier returns a successful +Result+" do

    before { expect(success_cases).to_not be_empty }

    it "returns the cancelled reservation id" do
      success_cases.each do |kase|
        response = call(described_class.new, kase[:params].dup)
        expect(response.status).to eq 200
        expect(response.body["status"]).to eq "ok"
        expect(response.body["cancelled_reference_number"]).to eq kase[:cancelled_reference_number]
      end
    end
  end
end

RSpec.shared_examples "Zendesk cancellation notification" do |supplier:|
  include Support::HTTPStubbing

  let(:params) { { reference_number: "123", inquiry_id: "392" } }
  let(:zendesk_notify_url) { "https://www.zendesk-notify-example.org" }

  before do
    ENV["ZENDESK_NOTIFY_URL"] = zendesk_notify_url
  end

  after do
    ENV.delete("ZENDESK_NOTIFY_URL")
  end

  it "sends a ticket to Zendesk upon cancellation" do
    stub_call(:post, zendesk_notify_url) { [200, {}, { "status" => "ok" }.to_json] }

    expect_any_instance_of(API::Support::ZendeskNotify).to receive(:notify).
      with("cancellation", { supplier: supplier, supplier_id: "123", bridge_id: "392" }).
      once.and_call_original

    subject.call(params)
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
