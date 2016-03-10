RSpec.shared_examples "external error reporting" do

  it "returns an error message in case there is a failure with the request" do
    stub_call(:post, endpoint) { raise Faraday::TimeoutError }
    response = nil

    expect {
      response = parse_response(described_class.new.call(params))
    }.to change { ExternalErrorRepository.count }.by(1)

    expect(response.status).to eq 503
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["quote"]).to eq "Could not quote price with remote supplier"

    error = ExternalErrorRepository.most_recent
    expect(error).to be_a ExternalError
    expect(error.operation).to eq "quote"
    expect(error.supplier).to eq supplier_name
    expect(error.code).to eq "connection_timeout"
    expect(error.message).to eq "timeout"
    expect(error.happened_at).to be_a Time
  end

  def parse_response(rack_response)
    Shared::QuoteResponse.new(
      rack_response[0],
      rack_response[1],
      JSON.parse(rack_response[2].first)
    )
  end

end
