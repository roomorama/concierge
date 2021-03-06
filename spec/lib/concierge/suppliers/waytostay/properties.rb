RSpec.shared_examples "Waytostay property client" do
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
    context "when there are no single beds" do
      let(:response) {
        Concierge::SafeAccessHash.new( "general" => {
          "bedding_summary"=>["1 double sofa bed"]
        })
      }
      it { expect(subject[:number_of_sofa_beds]).to eq 1 }
      it { expect(subject[:number_of_single_beds]).to eq 0 }
    end
  end

  describe "#parse_amenities" do
    subject { described_class.new.send(:parse_amenities, response) }

    context "when everything is present" do
      let(:response) { Concierge::SafeAccessHash.new(
        JSON.parse(read_fixture("waytostay/properties/amenities_all_present.json")))
      }
      it { expect(subject[:amenities]).to match [
          "internet", "tv", "cabletv", "airconditioning",
          "laundry", "balcony", "outdoor_space", "pool", "parking", "elevator",
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

  describe "#parse_security_deposit_method" do
    subject { described_class.new.send(:parse_security_deposit_method, response) }

    context "when card and cash is accepted" do
      let(:response) { Concierge::SafeAccessHash.new(
        { payment:
          { damage_deposit_payment_methods:
            [ { "id" => 1, "name" => "card details will be taken" },
              { "id" => 2, "name" => "cash" }]
          }
        })
      }
      it { expect(subject[:security_deposit_type]).to eq "cash" }
    end

    context "when cash is not accepted but card is" do
      let(:response) { Concierge::SafeAccessHash.new(
        { payment:
          { damage_deposit_payment_methods:
            [ { "id" => 1, "name" => "credit card details will be taken" } ]
          }
        })
      }
      it { expect(subject[:security_deposit_type]).to eq "credit_card_auth" }
    end

    context "when only cheque is accepted" do
      let(:response) { Concierge::SafeAccessHash.new(
        { payment:
          { damage_deposit_payment_methods:
            [ { "id" => 1, "name" => "traveller’s cheques" } ]
          }
        })
      }
      it { expect(subject[:security_deposit_type]).to eq "check" }
    end
  end

  describe "#get_property" do
    let(:valid_property_id)           { "015868" }
    let(:inactive_property_id)        { "inactive" }
    let(:partial_payment_property_id) { "102" }
    let(:property_url) { "#{base_url}/properties/#{property_id}" }
    before do
      stubbed_client.oauth2_client.oauth_client.connection = stub_call(:get, property_url) {
        [200, {}, read_fixture("waytostay/properties/#{property_id}.json")]
      }
    end

    subject { stubbed_client.get_property(property_id) }

    context "when property is valid and active" do
      let(:property_id) { valid_property_id }
      let(:required_attributes) { [:identifier, :type, :title,
        :description, :number_of_bedrooms, :max_guests, :minimum_stay,
        :nightly_rate, :weekly_rate, :monthly_rate, :default_to_available] }

      it "should return a Roomorama::Property" do
        expected_room_load = Roomorama::Property.load(
          Concierge::SafeAccessHash.new( # use this because #load expects keys in symbols
            JSON.parse(read_fixture("waytostay/properties/#{property_id}.roomorama-attributes.json"))
          )
        )
        room_without_images = expected_room_load.result.to_h
        room_without_images[:images] = []
        expect(subject.value.to_h).to match room_without_images
        expect(required_attributes - subject.result.to_h.keys).to be_empty
      end
    end

    context "when property is inactive" do
      let(:property_id) { inactive_property_id }
      it { expect(subject.result.disabled).to eq true }
    end

    context "when property payment method is not supported" do
      let(:property_id) { partial_payment_property_id }
      it { expect(subject.result.disabled).to eq true }
    end

    context "when property has empty postal code" do
      let(:property_id) { "empty_postal_code" }
      it "should be successful" do
        expect(subject).to be_success
        expect(subject.value.to_h[:postal_code]).to be_nil
        expect(subject.value.to_h[:address]).to_not be_nil
      end
    end
  end

  describe "#get_properties_by_ids" do
    subject { stubbed_client.get_properties_by_ids(["016233", "016206"]) }
    before do
        stubbed_client.oauth2_client.oauth_client.connection = stub_call(:get, base_url + Waytostay::Properties::INDEX_ENDPOINT) {
          [200, {}, read_fixture("waytostay/properties.json")]
        }
    end
    it { expect(subject.value.count).to eq 2 }
  end

  describe "#get_active_properties" do

    subject { stubbed_client.get_active_properties(page) }

    context "on first page" do
      let(:page) { 1 }

      before do
        stubbed_client.oauth2_client.oauth_client.connection = stub_call(:get, base_url + Waytostay::Properties::INDEX_ENDPOINT) {
          [200, {}, read_fixture("waytostay/properties.json")]
        }
      end

      it "should return the next page and one Result wrapping many Results of Roomorama::Property" do
        expect(subject[0]).to be_success
        expect(subject[0].value.first).to be_success
        expect(subject[0].value.first.value).to be_a Roomorama::Property
        expect(subject[1]).to eq 2
      end
    end

    context "on last page" do
      let(:page) { 94 }

      before do
        stubbed_client.oauth2_client.oauth_client.connection = stub_call(:get, base_url + Waytostay::Properties::INDEX_ENDPOINT) {
          [200, {}, read_fixture("waytostay/properties.last.json")]
        }
      end

      it "should return the next page and one Result wrapping many Results of Roomorama::Property" do
        expect(subject[0]).to be_success
        expect(subject[0].value.first).to be_success
        expect(subject[0].value.first.value).to be_a Roomorama::Property
        expect(subject[1]).to be_nil
      end
    end
  end

  describe "#get_property_from_batch" do

    subject { stubbed_client.get_property_from_batch("002", ["001", "002"]) }

    it "calls batch properties api" do
      expect_any_instance_of(Waytostay::Client).to receive(:get_properties_by_ids) do |client, ids|
        Result.new ids.collect { |ref| Roomorama::Property.load(
            Concierge::SafeAccessHash.new(
              JSON.parse(read_fixture("waytostay/properties/#{ref}.roomorama-attributes.json"))
            )) }
      end
      expect(subject).to be_success
      expect(subject.value).to be_a Roomorama::Property
    end

  end

  describe "#add_late_checkin_fees" do
    let(:property) { Roomorama::Property.new('test') }
    let(:response) {
      Concierge::SafeAccessHash.new(
        "general" => {
          "late_checkin_possible" => true,
          "late_checkin_from" => "22:00",
          "late_checkin_to" => "08:00",
          "late_checkin_fee" => "30"
        },
        "payment" => {
          "currency" => "USD"
        }
      )
    }

    before {
      property.description_append ||= ""
      property.de.description_append ||= ""
      property.es.description_append ||= ""
      property.zh.description_append ||= ""
      property.zh_tw.description_append ||= ""

      described_class.new.send(:add_late_checkin_fee, property, response)
    }

    it "should be correct" do
      expect(property.description_append).to eq "Late check-in fees from 22:00 to 08:00 - 30 USD\n"
      expect(property.de.description_append).to eq "Gebühr in Höhe von 30 USD für späte Anreise (22:00 bis 08:00)\n"
      expect(property.es.description_append).to eq "Tarde de facturación de 22:00 a 08:00 - 30 USD\n"
      expect(property.zh.description_append).to eq "延迟入住费从22:00至08:00  -  30 USD\n"
      expect(property.zh_tw.description_append).to eq "延遲入住費從22:00至08:00  -  30 USD\n"
    end

    context "late checkin not possible" do
      let(:response) {
        Concierge::SafeAccessHash.new(
          "general" => {
            "late_checkin_possible" => false,
            "late_checkin_from" => "22:00",
            "late_checkin_to" => "08:00",
            "late_checkin_fee" => "30"
          },
          "payment" => {
            "currency" => "USD"
          }
        )
      }

      it "should not append to description_apend" do
        expect(property.description_append).to eq ""
        expect(property.de.description_append).to eq ""
        expect(property.es.description_append).to eq ""
        expect(property.zh.description_append).to eq ""
        expect(property.zh_tw.description_append).to eq ""
      end
    end
  end

  describe "#add_license_number" do

    let(:property) { Roomorama::Property.new('test') }
    before {
      property.description_append ||= ""
      property.de.description_append ||= ""
      property.es.description_append ||= ""
      property.zh.description_append ||= ""
      property.zh_tw.description_append ||= ""

      described_class.new.send(:add_license_number, property, response)
    }

    context "when license is empty" do
      let(:response) {
        Concierge::SafeAccessHash.new(
          "general" => {
            "licence_number" => ""
          }
        )
      }
      it "should not add description and translations" do
        expect(property.description_append).to eq ""
        expect(property.de.description_append).to eq ""
        expect(property.es.description_append).to eq ""
        expect(property.zh.description_append).to eq ""
        expect(property.zh_tw.description_append).to eq ""
      end
    end

    context "when license is present" do
      let(:response) {
        Concierge::SafeAccessHash.new(
          "general" => {
            "licence_number" => "ABC"
          }
        )
      }
      it "should not add description and translations" do
        expect(property.description_append).to eq "License number: ABC\n"
        expect(property.de.description_append).to eq "Lizenznummer: ABC\n"
        expect(property.es.description_append).to eq "Número de licencia: ABC\n"
        expect(property.zh.description_append).to eq "许可证号: ABC\n"
        expect(property.zh_tw.description_append).to eq "許可證號: ABC\n"
      end
    end
  end

end
