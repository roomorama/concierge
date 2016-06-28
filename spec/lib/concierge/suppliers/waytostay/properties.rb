RSpec.shared_examples "Waytostay property handler" do
  include Support::Fixtures

  describe "#parse_number_of_beds" do
    subject { described_class.new.send(:parse_number_of_beds, response) }
    context "when there are single and double sofa beds" do
      let(:response) {
        Concierge::SafeAccessHash.new( "general" => {
          "bedding_summary"=>[
            "1 single sofa bed",
            "2 double bed",
            "4 single bed",
            "1 double sofa bed"]}
        )
      }
      it { expect(subject[:number_of_double_beds]).to eq 2 }
      it { expect(subject[:number_of_single_beds]).to eq 4 }
      it { expect(subject[:number_of_sofa_beds]).to eq 2 }
    end
    context "when there are no signle sofa beds" do
      let(:response) {
        Concierge::SafeAccessHash.new( "general" => {
          "bedding_summary"=>[
            "2 double bed",
            "4 single bed",
            "1 double sofa bed"]}
        )
      }
      it { expect(subject[:number_of_sofa_beds]).to eq 1 }
    end
  end

  describe "#parse_amenities" do
    subject { described_class.new.send(:parse_amenities, response) }

    context "when everything is present" do
      let(:response) { Concierge::SafeAccessHash.new(
        JSON.parse(read_fixture("waytostay/properties/amenities_all_present.json")))
      }
      it { expect(subject[:amenities]).to match [
          "internet", "cabletv", "tv", "parking", "airconditioning",
          "laundry", "pool", "elevator", "balcony", "outdoor_space",
          "kitchen", "wifi", "free_cleaning", "bed_linen_and_towels"
        ]
      }
    end

    context "when nothing is present" do
      let(:response) { Concierge::SafeAccessHash.new(
        JSON.parse(read_fixture("waytostay/properties/amenities_nothing_present.json")))
      }
      it { expect(subject[:amenities]).to match [] }
    end
  end

end
