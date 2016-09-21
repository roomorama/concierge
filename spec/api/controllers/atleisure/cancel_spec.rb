require 'spec_helper'
require_relative "../shared/cancel"

RSpec.describe API::Controllers::AtLeisure::Cancel do
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
      with("cancellation", { supplier: "AtLeisure", supplier_id: "123", bridge_id: "392" }).
      once.and_call_original

    subject.call(params)
  end
end
