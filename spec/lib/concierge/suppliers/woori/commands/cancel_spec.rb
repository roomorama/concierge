require "spec_helper"

RSpec.describe Woori::Commands::Cancel do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:subject) { described_class.new(credentials) }
  let(:url) { "http://my.test/reservation/cancel" }
  let(:reference_number) { "w_WP20160801020909446E" }

  it "successfully cancels the reservation" do
    stub_data = read_fixture("woori/cancellations/success.json")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.call(reference_number)
    expect(result).to be_success
    expect(result.value).to eq(reference_number)
  end

  it "returns a result with error if reservation failed by unknown reason" do
    stub_data = read_fixture("woori/cancellations/unknown_error.json")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.call(reference_number)
    expect(result).not_to be_success
    expect(result.error.code).to eq(:reservation_cancel_error)

    context_event = Concierge.context.events.last.to_h
    expect(context_event[:message]).to eq(
      "Unknown error during cancellation of reservation `#{reference_number}`"
    )
    expect(context_event[:backtrace]).to be_kind_of(Array)
    expect(context_event[:backtrace].any?).to be true
  end

  context "when response from the Woori api is not well-formed json" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("woori/bad_response.json")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.call(reference_number)

      expect(result).not_to be_success
      expect(result.error.code).to eq(:invalid_json_representation)
    end
  end

  context "when incorrect booking_ref_number is provided" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("woori/cancellations/unknown_error.json")
      stub_call(:post, url) { [500, {}, stub_data] }

      result = subject.call(reference_number)

      expect(result).not_to be_success
      expect(result.error.code).to eq(:http_status_500)
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:post, url) { raise Faraday::TimeoutError }

      result = subject.call(reference_number)

      expect(result).not_to be_success
      expect(Concierge.context.events.last.to_h[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
    end
  end
end
