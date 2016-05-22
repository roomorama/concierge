require "spec_helper"

RSpec.describe API::Middlewares::RequestContext do
  let(:upstream) { lambda { |env| [200, {}, "OK"] } }
  let(:app) { Rack::MockRequest.new(subject) }
  let(:request_body) { { inquiry: { room_id: 123 } }.to_json }
  let(:headers) {
    {
      input: request_body,
      "SERVER_PROTOCOL"    => "HTTP/1.1",
      "HTTP_HOST"          => "concierge.roomorama.com",
      "SERVER_SOFTWARE"    => "WEBrick/1.3.1 (Ruby/2.3.0/2015-12-25)",
      "HTTP_CONNECTION"    =>"keep-alive",
      "HTTP_CACHE_CONTROL" =>"max-age=0"
    }
  }

  subject { described_class.new(upstream) }

  it "initializes the request context and includes request information" do
    allow(Time).to receive(:now) { Time.new("2016", "05", "21") }

    previous_context = API.context
    expect(post("/jtb/quote", headers)).to eq upstream_response

    expect(API.context).to be_a Concierge::Context
    expect(API.context.object_id).not_to eq previous_context.object_id
    expect(API.context.events.size).to eq 1
    expect(API.context.events.first.to_h).to eq({
      type:        "incoming_request",
      timestamp:   Time.now,
      http_method: "POST",
      headers: {
        "Host"          => "concierge.roomorama.com",
        "Connection"    => "keep-alive",
        "Cache-Control" => "max-age=0"
      },
      body: request_body,
      path: "/jtb/quote"
    })
  end

  def upstream_response
    [200, { "Content-Length" => "2" }, "OK"]
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
