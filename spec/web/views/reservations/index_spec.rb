require "spec_helper"

RSpec.describe Web::Views::Reservations::Index do
  include Support::Factories

  let(:reservations) { ReservationRepository.reverse_date }
  let(:exposures)    { Hash[reservations: reservations] }
  let(:template)     { Hanami::View::Template.new('apps/web/templates/reservations/index.html.erb') }
  let(:view)         { described_class.new(template, exposures) }
  let(:rendered)     { view.render }

  let(:sanitized) { rendered.gsub("\n", "").gsub(/\s\s+/, " ") }

  before do
    2.times.map { |n| create_reservation(property_id: "property#{n}", supplier: "Supplier#{n}") }
  end

  it "includes the supplier that provides the booked property" do
    [0, 1].each do |id|
      expect(sanitized).to include %(<td>Supplier#{id}</td>)
    end
  end

  it "renders a list of reservations" do
    [0, 1].each do |id|
      expect(sanitized).to include %(<td> <code>property#{id}</code> </td>)
    end
  end

  it "renders the unit ID for multi-unit reservations" do
    create_reservation(property_id: "property3", unit_id: "unit1")
    expect(sanitized).to include %(<td> <code>property3</code> / <code>unit1</code> </td>)
  end

  it "properly formats the reservation creation time" do
    reservations = ReservationRepository.all.to_a
    reservations.first.created_at = Time.new(2016, 5, 12, 12, 33)
    reservations.last.created_at =  Time.new(2016, 5, 14, 2, 51)

    ReservationRepository.persist(reservations.first)
    ReservationRepository.persist(reservations.last)

    expect(sanitized).to include %(<td>May 12, 2016 at 12:33</td>)
    expect(sanitized).to include %(<td>May 14, 2016 at 02:51</td>)
  end
end
