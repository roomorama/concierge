RSpec.shared_examples "Kigo price quotation" do
  it "returns an error message in case there is a failure with the request" do
    stub_call(:post, endpoint) { raise Faraday::TimeoutError }
    response = parse_response(described_class.new.call(params))

    expect(response.status).to eq 503
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["quote"]).to eq "Could not quote price with remote supplier"
  end

  ["kigo/e_nosuch.json"].each do |fixture|
    it "returns a proper error message if return looks like fixture #{fixture}" do
      stub_call(:post, endpoint) { [200, {}, read_fixture(fixture)] }
      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["quote"]).to eq "The `API_RESULT_CODE` obtained was not equal to `E_OK`. Check Kigo's API documentation for an explanation for the `API_RESULT_CODE` returned."
    end
  end

  ["kigo/no_api_reply.json", "kigo/no_total.json"].each do |fixture|
    it "returns a proper error message if return looks like fixture #{fixture}" do
      stub_call(:post, endpoint) { [200, {}, read_fixture(fixture)] }
      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["quote"]).to eq "Could not quote price with remote supplier"
    end
  end

  it "returns unavailable quotation when the supplier responds so" do
    stub_call(:post, endpoint) { [200, {}, read_fixture("kigo/unavailable.json")] }
    response = parse_response(described_class.new.call(params))

    expect(response.status).to eq 200
    expect(response.body["status"]).to eq "ok"
    expect(response.body["available"]).to eq false
    expect(response.body["property_id"]).to eq "567"
    expect(response.body["check_in"]).to eq "2016-03-22"
    expect(response.body["check_out"]).to eq "2016-03-25"
    expect(response.body["guests"]).to eq 2
    expect(response.body).not_to have_key("currency")
    expect(response.body).not_to have_key("total")
  end

  it "returns unavailable quotation if no rates for the property are available" do
    stub_call(:post, endpoint) { [200, {}, read_fixture("kigo/no_rates.json")] }
    response = parse_response(described_class.new.call(params))

    expect(response.status).to eq 200
    expect(response.body["status"]).to eq "ok"
    expect(response.body["available"]).to eq false
    expect(response.body["property_id"]).to eq "567"
    expect(response.body["check_in"]).to eq "2016-03-22"
    expect(response.body["check_out"]).to eq "2016-03-25"
    expect(response.body["guests"]).to eq 2
    expect(response.body).not_to have_key("currency")
    expect(response.body).not_to have_key("total")
  end

  it "returns unavailable quotation if there are no availabilities, or it is booked" do
    stub_call(:post, endpoint) { [200, {}, read_fixture("kigo/e_empty.json")] }
    response = parse_response(described_class.new.call(params))

    expect(response.status).to eq 200
    expect(response.body["status"]).to eq "ok"
    expect(response.body["available"]).to eq false
    expect(response.body["property_id"]).to eq "567"
    expect(response.body["check_in"]).to eq "2016-03-22"
    expect(response.body["check_out"]).to eq "2016-03-25"
    expect(response.body["guests"]).to eq 2
    expect(response.body).not_to have_key("currency")
    expect(response.body).not_to have_key("total")
  end

  context "success" do
    before { stub_call(:post, endpoint) { [200, {}, read_fixture("kigo/success.json")] } }

    it "returns available quotations with price when the call is successful" do
      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "ok"
      expect(response.body["available"]).to eq true
      expect(response.body["property_id"]).to eq "567"
      expect(response.body["check_in"]).to eq "2016-03-22"
      expect(response.body["check_out"]).to eq "2016-03-25"
      expect(response.body["guests"]).to eq 2
      expect(response.body["currency"]).to eq "EUR"
      expect(response.body["total"]).to eq 570.0
    end

    it "returns available quotations with gross rate" do
      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "ok"
      expect(response.body["available"]).to eq true
      expect(response.body["property_id"]).to eq "567"
      expect(response.body["check_in"]).to eq "2016-03-22"
      expect(response.body["check_out"]).to eq "2016-03-25"
      expect(response.body["guests"]).to eq 2
      expect(response.body["currency"]).to eq "EUR"
      expect(response.body["net_rate"]).to eq 532.71
      expect(response.body["total"]).to eq 570.0
      expect(response.body["host_fee"]).to eq 37.29
      expect(response.body["host_fee_percentage"]).to eq 7
    end

  end


  def parse_response(rack_response)
    Support::HTTPStubbing::ResponseWrapper.new(
      rack_response[0],
      rack_response[1],
      JSON.parse(rack_response[2].first)
    )
  end
end
