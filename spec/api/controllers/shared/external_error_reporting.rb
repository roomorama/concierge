RSpec.shared_examples "external error reporting" do

  # checks that a given quotation controller properly handles external failures recording.
  #
  # Assumptions:
  #
  #   * +provoke_failure!+ method: sets up any stubbing necessary to provoke an external
  #   failure in the API call. This method should return an object that responds to +code+
  #   and +message+ to be checked against the +ExternalError+ record added at the end
  #   of the API call.
  #
  #   * +supplier_name+: this must be defined to the currently running supplier
  #   specs.
  it "returns an error message in case there is a failure with the request" do
    failure = provoke_failure!
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
    expect(error.code).to eq failure.code
    expect(error.context).to be_a Concierge::SafeAccessHash
    expect(error.happened_at).to be_a Time
  end

  def parse_response(rack_response)
    Support::HTTPStubbing::ResponseWrapper.new(
      rack_response[0],
      rack_response[1],
      JSON.parse(rack_response[2].first)
    )
  end

end