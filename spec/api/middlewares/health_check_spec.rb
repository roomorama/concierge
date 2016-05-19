require "spec_helper"

RSpec.describe API::Middlewares::HealthCheck do
  let(:upstream) { lambda { |env| [200, {}, "OK"] } }
  let(:app) { Rack::MockRequest.new(subject) }

  subject { described_class.new(upstream) }

  before do
    allow(Time).to receive(:now) { Time.new(2016, 3, 22, 11, 22, 33, 0) } # 2016-03-22 11:22:33 +0000
  end

  it "returns a successful response to health checks" do
    expect(get("/_ping")).to eq health_check_response
  end

  it "returns the upstream response in case the request is not a health check" do
    expect(post("/jtb/quote")). to eq upstream_response
  end

  def health_check_response
    response = {
      status: "ok",
      app:  "api",
      time: Time.now.strftime("%Y-%m-%d %T %Z"),
      version: Concierge::VERSION
    }.to_json

    [200, { "Content-Length" => response.size.to_s, "Content-Type" => "application/json" }, response]
  end

  def upstream_response
    [200, { "Content-Length" => "2" }, "OK"]
  end

  def get(path, params = {})
    to_rack(app.get(path, params))
  end

  def post(path, params = {})
    to_rack(app.post(path, params))
  end

  def to_rack(response)
    [
      response.status,
      response.header,
      response.body
    ]
  end
end
