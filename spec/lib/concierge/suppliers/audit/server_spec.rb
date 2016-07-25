require "spec_helper"

RSpec.describe Audit::Server do
  include Support::Fixtures

  let(:app) { ->(env) { [200, env, "app"] } }
  let(:middleware) { described_class.new(Rack::Static.new(app, urls: ['/spec'])) }

  it "serves success files as-is" do
    file = %w[
      spec/fixtures/audit/cancel.success.json
      spec/fixtures/audit/quotation.success.json
    ].sample
    code, env, response = middleware.call Rack::MockRequest.env_for("http://admin.example.com/#{file}", {})
    expect(code).to eq(200)
    expect(response_body_as_string(response)).to eq(IO.read file)
  end

  it "serves connection_timeout with correct content but after CONNECTION_TIMEOUT seconds delay" do
    # we could do a start/end check.. but that'll make test slower
    expect(middleware).to receive(:sleep).with(Concierge::HTTPClient::CONNECTION_TIMEOUT + 1).and_return(nil)

    file = %w[
      spec/fixtures/audit/cancel.success.json
      spec/fixtures/audit/quotation.success.json
    ].sample
    code, env, response = middleware.call Rack::MockRequest.env_for("http://admin.example.com/#{file.gsub("success", "connection_timeout")}", {})
    expect(code).to eq(200)
    expect(response_body_as_string(response)).to eq(IO.read file)
  end

  it "serves successful booking with random `reference_number`" do
    file = "spec/fixtures/audit/booking.success.json"
    code, env, response = middleware.call Rack::MockRequest.env_for("http://admin.example.com/#{file}", {})
    expect(code).to eq(200)
    file_json = JSON.parse(IO.read file)
    resp_json = JSON.parse(response_body_as_string(response))
    expect(resp_json).not_to eq(file_json)
    expect(result_without_key resp_json, 'reference_number').to eq(result_without_key file_json, 'reference_number')
  end

  it "serves wrong_json with a wrong but valid json string" do
    file = Dir["spec/fixtures/audit/*.success.json"].sample.gsub("success", "wrong_json")
    code, env, response = middleware.call Rack::MockRequest.env_for("http://admin.example.com/#{file}", {})
    expect(code).to eq(200)
    expect(response_body_as_string(response)).to eq("[1, 2, 3]")
  end

  it "serves invalid_json with an invalid json string" do
    file = Dir["spec/fixtures/audit/*.success.json"].sample.gsub("success", "invalid_json")
    code, env, response = middleware.call Rack::MockRequest.env_for("http://admin.example.com/#{file}", {})
    expect(code).to eq(200)
    expect(response_body_as_string(response)).to eq("{")
  end

  def result_without_key(hash, key)
    hash['result'].delete(key)
    hash
  end

  def response_body_as_string(response)
    case response
    when Rack::File
      IO.read response.path
    else
      response.join("")
    end
  end
end
