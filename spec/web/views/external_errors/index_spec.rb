require "spec_helper"

RSpec.describe Web::Views::ExternalErrors::Index do
  let(:errors)    { 2.times.map { |n| generate_error(n + 1) } }
  let(:exposures) { Hash[external_errors: errors, params: params] }
  let(:template)  { Hanami::View::Template.new('apps/web/templates/external_errors/index.html.erb') }
  let(:view)      { described_class.new(template, exposures) }
  let(:rendered)  { view.render }

  def params(hash = nil)
    if hash
      @params = Web::Controllers::ExternalErrors::Index::Params.new(hash)
    else
      @params
    end
  end

  before do
    params({})
  end

  it "renders a list of external errors" do
    [1, 2].each do |id|
      expect(rendered).to include %(<td>Supplier#{id}</td>)
      expect(rendered).to include %(<td>error_#{id}</td>)
      expect(rendered).to include %(<td>description_#{id}</td>)
    end
  end

  it "renders a link to the show page of an error" do
    expect(rendered).to include %(<a href="/errors/1">#1</a>)
  end

  context "pagination links" do
    it "renders the next and previous page links" do
      params page: 2

      expect(rendered).to include %(<a href="/errors?page=1">❮ Prev</a>)
      expect(rendered).to include %(<a href="/errors?page=3">Next ❯</a>)
    end

    it "does not render the previous link if on the first page" do
      expect(rendered).not_to include %(❮ Prev)
      expect(rendered).to include %(<a href="/errors?page=2">Next ❯</a>)
    end

    it "includes existing parameters in the pagination links" do
      params page: 2, supplier: "Supplier", per: 100

      expect(rendered).to include %(<a href="/errors?page=1&supplier=Supplier&per=100">❮ Prev</a>)
      expect(rendered).to include %(<a href="/errors?page=3&supplier=Supplier&per=100">Next ❯</a>)
    end
  end

  def generate_error(id)
    double(
      id:          id,
      operation:   id.odd? ? "quote" : "booking",
      supplier:    "Supplier#{id}",
      code:        "error_#{id}",
      description: "description_#{id}",
      happened_at: Time.now - id * 24 * 60 * 60 # +id+ days ago
    )
  end
end
