require "spec_helper"

RSpec.describe Web::Views::ExternalErrors::Show do
  include Support::Factories

  let(:host)         { create_host(identifier: 'test-host', username: 'test-username') }
  let(:sync_process) { create_sync_process(host_id: host.id) }
  let(:event) do
    Concierge::SafeAccessHash.new(
      sync_process.to_h.merge!(
        identifier: '123',
        timestamp: Time.now.to_s
      )
    )
  end
  let(:template)     { Hanami::View::Template.new('apps/web/templates/external_errors/events/_sync_process.html.erb') }

  # Hanami has a weird issue when rendering partials on the test environment when
  # the views are initialized as above (as suggested on the official guides). For some
  # reason, the format is not recognised, and it fails to render with a cryptic error
  # message.
  #
  # Hardcoding the format to +html+ for the rendered view allows the specs to pass.
  # TODO get rid of this when upgrading Hanami, hopefully it will have been fixed.
  let(:exposures)    { Hash[event: event, format: :html, flash: {}] }
  let(:view)         { described_class.new(template, exposures) }
  let(:rendered)     { view.render }

  it "renders a view" do
    expect { rendered }.not_to raise_error
  end

  it "has description" do
    expect(rendered).to include %(<p>The availabilities synchronisation process started for property <code>123</code>,\n    from host <code>test-username</code> (identifier: <code>test-host</code>).</p>)
  end

  describe "when host is no longer exist in the database" do
    let(:event) do
      sync_process.to_h.merge!(
        identifier: '123',
        host_id:    999888,
        timestamp: Time.now.to_s
      )
    end

    it "has description saying it's no longer in the database" do
      expect(rendered).to include %(<p>The availabilities synchronisation process started for property <code>123</code>,\n    from host of ID <code>999888</code>, no longer in the database.</p>)
    end
  end
end
