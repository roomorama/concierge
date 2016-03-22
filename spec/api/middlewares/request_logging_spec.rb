require "spec_helper"

RSpec.describe API::Middlewares::RequestLogging do
  let(:upstream) { lambda { |env| [200, {}, "OK"] } }
  let(:app) { Rack::MockRequest.new(subject) }
  let(:request_body) { { inquiry: { room_id: 123 } }.to_json }
  let(:headers) { { input: request_body } }

  subject { described_class.new(upstream) }

  class TestRequestLogger
    attr_reader :messages

    def initialize
      @messages = []
    end

    def info(message)
      @messages << message
    end
  end

  let(:logger) { TestRequestLogger.new }

  before do
    allow(subject).to receive(:request_logger) { Concierge::RequestLogger.new(logger) }
  end

  it "logs requests including the request body if present" do
    expect(post("/jtb/quote", headers)).to eq upstream_response
    expect(logger.messages.first).to match %r(POST /jtb/quote \| T: \d\.\d\ds | S: 200\n#{request_body})
  end

  it "ignores the request body if there is none" do
    headers[:input] = ""

    expect(post("/jtb/quote", headers)).to eq upstream_response
    expect(logger.messages.first).to match %r(POST /jtb/quote \| T: \d\.\d\ds | S: 200)
  end

  def upstream_response
    [200, { "Content-Length" => "2" }, "OK"]
  end

  def sign(content, secret)
    encoded = Base64.encode64(content)
    digest  = OpenSSL::Digest.new("sha1")
    OpenSSL::HMAC.hexdigest(digest, secret, encoded)
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
