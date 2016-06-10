require "spec_helper"

RSpec.describe Web::Views::ExternalErrors::Show do
  let(:attributes) {
    {
      id: 1,
      operation: "quote",
      supplier: "JTB",
      code: "invalid_response",
      happed_at: Time.now - 2 * 24 * 60 * 60 # 2 days ago
    }
  }
  let(:context) { Concierge::Context.new }

  let(:event) {
    Concierge::Context::Message.new(
      label:     "Generic Error",
      message:   "Something went wrong",
      backtrace: []
    )
  }
  let(:error) { ExternalError.new(attributes) }
  let(:exposures) { Hash[error: error] }
  let(:template)  { Hanami::View::Template.new('apps/web/templates/external_errors/show.html.erb') }
  let(:view)      { described_class.new(template, exposures) }
  let(:rendered)  { view.render }

  before do
    context.augment(event)

    # overwrite +host+ information since it is different depending on the machine
    # that runs the tests.
    attributes[:context] = context.to_h.merge(host: "concierge-1")
  end

  describe "#legacy?" do
    it "is legacy if the version information on the context is missing" do
      context_data = context.to_h
      context_data.delete(:version)
      context_data.delete(:host)
      attributes[:context] = context_data

      expect(view).to be_legacy
    end

    it "is not legacy if the context has version information" do
      expect(view).not_to be_legacy
    end
  end

  describe "#concierge_version" do
    it "returns the running version of Concierge according to the data" do
      expect(view.concierge_version).to eq Concierge::VERSION
    end
  end

  describe "#concierge_host" do
    it "returns the host information according to the context data" do
      expect(view.concierge_host).to eq "concierge-1"
    end
  end

  describe "#events" do
    it "returns an Array of SafeAccessHash objects" do
      events = view.events
      expect(events).to be_a Array
      expect(events.size).to eq 1
      expect(events).to be_all { |event| event.is_a? Concierge::SafeAccessHash }
      expect(events.first[:type]).to eq "generic_message"
    end
  end

  describe "#partial_path" do
    it "returns the prefixed event type in case it is recognised" do
      event = view.events.first
      expect(view.partial_path(event)).to eq "external_errors/events/generic_message"
    end

    it "returns the path to the unrecognised event partial if the event is invalid" do
      attributes[:context][:events].first[:type] = "invalid"
      event = view.events.first

      expect(view.partial_path(event)).to eq "external_errors/events/unrecognised_event"
    end

    it "can find a proper partial for every supported event type" do
      (view.class::SUPPORTED_TYPES + %w(unrecognised_event)).each do |type|
        path = Web::Application.configuration.root.join("templates", "external_errors", "events", "_#{type}.html.erb").to_s
        expect(File).to be_exists(path), "No partial found for event type #{type}"
      end
    end
  end

  describe "#syntax_highlight_class" do
    it "uses the JSON class for that content type" do
      expect(view.syntax_highlight_class("application/json")).to eq "highlight json"
    end

    it "uses the XML class for that content type" do
      expect(view.syntax_highlight_class("text/xml")).to eq "highlight xml"
    end

    it "is nil in case the content type is unrecognised" do
      expect(view.syntax_highlight_class("text/html")).to be_nil
    end
  end

  describe "#pretty_print" do
    it "returns the content untouched if the content type is not recognised" do
      pretty = view.pretty_print("content", "application/html")
      expect(pretty).to eq "content"
    end

    it "returns the content untouched if it is declared to be JSON but it is invalid" do
      pretty = view.pretty_print("invalid-json", "application/json")
      expect(pretty).to eq "invalid-json"
    end

    it "returns the properly formatted, escaped JSON string in case it is valid" do
      content = { key: "value" }.to_json
      pretty  = view.pretty_print(content, "application/json")

      expect(pretty).to eq "" +
        %({\n\n) +
        %(  &quot;key&quot;: &quot;value&quot;\n\n) +
        %(})
    end

    it "doubles the line breaks for XML content and escapes the content" do
      content = "" +
        %(<response>\n) +
        %(  <status>200</status>\n) +
        %(</response>)

      expect(view.pretty_print(content, "text/xml")).to eq "" +
        %(&lt;response&gt;\n\n) +
        %(  &lt;status&gt;200&lt;&#x2F;status&gt;\n\n) +
        %(&lt;&#x2F;response&gt;)
    end

    it "is able to match the content type even with extra parameters" do
      content = { key: "value" }.to_json
      pretty  = view.pretty_print(content, "application/json; charset=utf-8")

      expect(pretty).to eq "" +
        %({\n\n) +
        %(  &quot;key&quot;: &quot;value&quot;\n\n) +
        %(})
    end
  end

  describe "#monospace" do
    it "wraps code tags for all text in backticks" do
      str = "Check the `errors` field, inside `response`, for details."
      expect(view.monospace(str)).to eq "Check the <code>errors</code> field, " +
        "inside <code>response</code>, for details."
    end

    it "leaves the content untouched if there is no content in backticks" do
      str = "Check the errors field, inside response, for details."
      expect(view.monospace(str)).to eq str
    end
  end

  describe "#format_timestamp" do
    it "formats the timestamp, including the timezone offset" do
      attributes[:context][:events].first[:timestamp] = Time.new("2016", "05", "25", "19", "32", "51", "+08:00").to_s

      expect(view.format_timestamp(error.context[:events].first)).to eq "19:32:51 (+0800)"
    end
  end
end
