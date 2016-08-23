require "spec_helper"

RSpec.describe API::Middlewares::Authentication do
  let(:upstream) { lambda { |env| [200, {}, "OK"] } }
  let(:app) { Rack::MockRequest.new(subject) }
  let(:body) { { inquiry: { room_id: 123 } }.to_json }
  let(:headers) {
    {
      input: body, # this is where Rack gets the request body from
      "CONTENT_TYPE"           => "application/json",
      "HTTP_CONTENT_SIGNATURE" => sign(body, secret)
    }
  }
  let(:secret) { "secret-key" }
  let(:secret_mapping) {
    { "/supplier" => secret }
  }
  let(:secrets) { API::Middlewares::Authentication::Secrets.new(secret_mapping) }

  subject { described_class.new(upstream, secrets) }

  it "is valid if it is a POST request with content-type and correct signature" do
    expect(post("/supplier/quote", headers)).to eq success
  end

  it "is valid if it is a POST with content-type and a whitelisted endpoint" do
    expect(post("/checkout", headers)).to eq success
  end

  it "is valid if it is a GET with content-signature" do
    path = "/kigo/image/123/45"
    get_headers = { "HTTP_CONTENT_SIGNATURE" => sign(path, secret)}
    expect(get(path, get_headers)).to eq success
  end

  it "is forbidden without a request body" do
    headers.delete(:input)
    expect(post("/supplier/quote", headers)).to eq forbidden
  end

  it "is forbidden if the path is not recognized" do
    expect(post("/malicious/quote", headers)).to eq forbidden
  end

  it "is forbidden withe root path" do
    expect(post("/", headers)).to eq forbidden
  end

  it "is forbidden for GET requests" do
    expect(get("/supplier/quote", headers)).to eq forbidden
  end

  it "is forbidden without a content-type header" do
    headers.delete("CONTENT_TYPE")
    expect(post("/supplier/quote", headers)).to eq forbidden
  end

  it "is forbidden without a signature header" do
    headers.delete("HTTP_CONTENT_SIGNATURE")
    expect(post("/supplier/quote", headers)).to eq forbidden
  end

  it "is forbidden if the secret used in the signature is different" do
    headers["HTTP_CONTENT_SIGNATURE"] = sign(body, "malicious_secret")
    expect(post("/supplier/quote", headers)).to eq forbidden
  end

  def sign(content, secret)
    encoded = Base64.encode64(content)
    digest  = OpenSSL::Digest.new("sha1")
    OpenSSL::HMAC.hexdigest(digest, secret, encoded)
  end

  def forbidden
    [403, { "Content-Length" => "9" }, "Forbidden"]
  end

  def success
    [200, { "Content-Length" => "2" }, "OK"]
  end

  def get(path, headers = {})
    to_rack(app.get(path, headers))
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
