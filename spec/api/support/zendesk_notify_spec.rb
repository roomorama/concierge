require "spec_helper"

RSpec.describe API::Support::ZendeskNotify do
  include Support::HTTPStubbing

  let(:zendesk_notify_url) { "https://www.zendesk-notify-test.com/v1/production" }
  let(:ticket_id) { "cancellation" }
  let(:attributes) {
    {
      supplier:    "Supplier Y",
      supplier_id: "123",
      bridge_id:   "321"
    }
  }

  before do
    ENV["ZENDESK_NOTIFY_URL"] = zendesk_notify_url
  end

  after do
    ENV.delete("ZENDESK_NOTIFY_URL")
  end

  describe "#notify" do
    it "forwards an error at the HTTP level if it occurs" do
      stub_call(:post, zendesk_notify_url) { [500, {}, ""] }

      result = subject.notify(ticket_id, attributes)
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :http_status_500
    end

    it "is unsuccessful when the requested ticket ID is not valid" do
      ticket_id = "invalid_ticket_id"

      result = subject.notify(ticket_id, attributes)
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :zendesk_invalid_ticket
    end

    it "returns an unsuccessful result when the response contains garbage" do
      stub_call(:post, zendesk_notify_url) { [200, {}, "<garbage>*#&"] }

      result = subject.notify(ticket_id, attributes)
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it "returns an unsuccessful result in case the ticket cannot be sent" do
      stub_call(:post, zendesk_notify_url) {
        body = {
          status:  "error",
          message: "Failure to connect to the Zendesk API"
        }

        [200, {}, body.to_json]
      }

      result = subject.notify(ticket_id, attributes)
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :zendesk_notify_failure
      expect(result.error.data).to eq "Failure to connect to the Zendesk API"
    end

    it "returns a successful result in case the ticket is properly sent" do
      stub_call(:post, zendesk_notify_url) {
        body = {
          status:  "ok",
          message: "Ticket sent successfully"
        }

        [200, {}, body.to_json]
      }

      result = subject.notify(ticket_id, attributes)
      expect(result).to be_a Result
      expect(result).to be_success
    end
  end
end
