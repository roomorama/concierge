require "spec_helper"

RSpec.describe Web::Views::ExternalErrors::Index do
  let(:errors)    { 2.times.map { |n| generate_error(n + 1) } }
  let(:exposures) { Hash[external_errors: errors] }
  let(:template)  { Hanami::View::Template.new('apps/web/templates/external_errors/index.html.erb') }
  let(:view)      { described_class.new(template, exposures) }
  let(:rendered)  { view.render }

  it "renders a list of external errors" do
    [1, 2].each do |id|
      expect(rendered).to include %(<td>Supplier#{id}</td>)
      expect(rendered).to include %(<td>error_#{id}</td>)
    end
  end

  def generate_error(id)
    double(
      id:          id,
      operation:   id.odd? ? "quote_price" : "booking",
      supplier:    "Supplier#{id}",
      code:        "error_#{id}",
      happened_at: Time.now - id * 24 * 60 * 60 # +id+ days ago
    )
  end
end
