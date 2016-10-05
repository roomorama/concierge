require "spec_helper"

RSpec.describe RentalsUnited::Mappers::Owner do
  let(:owner_hash) do
    {
      "FirstName"   => "Foo",
      "SurName"     => "Bar",
      "CompanyName" => "RU Test",
      "Email"       => "foobar@gmail.com",
      "Phone"       => "519461272",
      "@OwnerID"    => "419680"
    }
  end

  let(:safe_hash) { Concierge::SafeAccessHash.new(owner_hash) }
  let(:subject) { described_class.new(safe_hash) }

  it "builds owner object" do
    owner = subject.build_owner
    expect(owner).to be_kind_of(RentalsUnited::Entities::Owner)
    expect(owner.id).to eq("419680")
    expect(owner.first_name).to eq("Foo")
    expect(owner.last_name).to eq("Bar")
    expect(owner.email).to eq("foobar@gmail.com")
    expect(owner.phone).to eq("519461272")
  end
end
