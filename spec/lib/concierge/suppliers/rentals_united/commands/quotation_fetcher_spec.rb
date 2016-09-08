require "spec_helper"

RSpec.describe RentalsUnited::Commands::QuotationFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:property_id) { "1234" }
  let(:quotation_params) do
    API::Controllers::Params::Quote.new(
      property_id: '1234',
      check_in: "2016-09-19",
      check_out: "2016-09-20",
      guests: 3
    )
  end
  let(:subject) { described_class.new(credentials, quotation_params) }
  let(:url) { credentials.url }

  it "performs successful request returning Quotation object" do
    stub_data = read_fixture("rentals_united/quotations/success.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.call

    expect(result).to be_kind_of(Result)
    expect(result).to be_success

    quotation = result.value
    expect(quotation).to be_kind_of(Quotation)
    expect(quotation.property_id).to eq(quotation_params[:property_id])
    expect(quotation.check_in).to eq(quotation_params[:check_in])
    expect(quotation.check_out).to eq(quotation_params[:check_out])
    expect(quotation.guests).to eq(quotation_params[:guests])
    expect(quotation.total).to eq(284.5)
    expect(quotation.currency).to eq('')
    expect(quotation.available).to be true
  end

  it "returns unavailable Quotation when property is not available" do
    stub_data = read_fixture("rentals_united/quotations/not_available.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.call

    expect(result).to be_kind_of(Result)
    expect(result).to be_success

    quotation = result.value
    expect(quotation).to be_kind_of(Quotation)
    expect(quotation.property_id).to eq(quotation_params[:property_id])
    expect(quotation.check_in).to eq(quotation_params[:check_in])
    expect(quotation.check_out).to eq(quotation_params[:check_out])
    expect(quotation.guests).to eq(quotation_params[:guests])
    expect(quotation.total).to eq(0)
    expect(quotation.available).to be false
  end

  it "returns an error when check_in is invalid" do
    stub_data = read_fixture("rentals_united/quotations/invalid_date_from.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.call

    expect(result).not_to be_success
    expect(result.error.code).to eq("74")

    event = Concierge.context.events.last.to_h
    expect(event[:message]).to eq(
      "Response indicating the Status with ID `74`, and description `DateFrom has to be earlier than DateTo.`"
    )
    expect(event[:backtrace]).to be_kind_of(Array)
    expect(event[:backtrace].any?).to be true
  end

  it "returns an error when num_guests are greater than allowed" do
    stub_data = read_fixture("rentals_united/quotations/too_many_guests.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.call

    expect(result).not_to be_success
    expect(result.error.code).to eq("76")

    event = Concierge.context.events.last.to_h
    expect(event[:message]).to eq(
      "Response indicating the Status with ID `76`, and description `Number of guests exceedes the maximum allowed.`"
    )
    expect(event[:backtrace]).to be_kind_of(Array)
    expect(event[:backtrace].any?).to be true
  end

  it "returns an error when num_guests are invalid" do
    stub_data = read_fixture("rentals_united/quotations/invalid_max_guests.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.call

    expect(result).not_to be_success
    expect(result.error.code).to eq("77")

    event = Concierge.context.events.last.to_h
    expect(event[:message]).to eq(
      "Response indicating the Status with ID `77`, and description `NOP: positive value required.`"
    )
    expect(event[:backtrace]).to be_kind_of(Array)
    expect(event[:backtrace].any?).to be true
  end

  context "when response from the api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/bad_xml.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.call

      expect(result).not_to be_success
      expect(result.error.code).to eq(:unrecognised_response)

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq(
        "Error response could not be recognised (no `Status` tag in the response)"
      )
      expect(event[:backtrace]).to be_kind_of(Array)
      expect(event[:backtrace].any?).to be true
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:post, url) { raise Faraday::TimeoutError }

      result = subject.call

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
