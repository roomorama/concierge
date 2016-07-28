require "spec_helper"

RSpec.describe SAW::Commands::CountryPropertiesFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  include Support::SAW::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }
  let(:country) { SAW::Entities::Country.new(id: 1, name: 'United States') }

  context "when response is empty" do
    it "returns an empty array in case if there are no properties" do
      mock_request(:propertysearch, :empty)

      result = subject.call(country)
      expect(result.success?).to be true

      properties = result.value
      expect(properties).to eq([])
    end
  end

  context "when response is error" do
    it "returns an empty array in case if there is an error in response" do
      mock_request(:propertysearch, :error)

      result = subject.call(country)
      expect(result.success?).to be false
      expect(result.error.code).to eq("9999")
      expect(last_context_event[:message]).to eq(
        "Response indicating the error `9999`, and description `Custom Error`"
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end
  end

  context "when response from the SAW api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      mock_bad_xml_request(:propertysearch)

      result = subject.call(country)

      expect(result.success?).to be false
      expect(result.error.code).to eq(:unrecognised_response)
      expect(last_context_event[:message]).to eq(
        "Error response could not be recognised (no `code` or `description` fields)."
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      mock_timeout_error(:propertysearch)

      result = subject.call(country)

      expect(result).not_to be_success
      expect(last_context_event[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
    end
  end

  context "when response is success" do
    before do
      mock_request(:propertysearch, :success)
    end

    let(:result) { subject.call(country) }
    let(:properties) { result.value }

    it "returns right number of properties" do
      expect(result.success?).to be true
      expect(properties.size).to eq(5)
    end

    it "returns correct-typed objects" do
      expect(properties).to all(
        be_an(SAW::Entities::BasicProperty)
      )
    end

    it "sets internal id for properties" do
      internal_ids = properties.map(&:internal_id)

      expect(internal_ids).to eq([1787, 1757, 2721, 2893, 1766])
    end

    it "sets room type for properties" do
      expect(properties).to all(
        have_attributes(type: 'apartment')
      )
    end

    it "sets title for properties" do
      titles = properties.map(&:title)

      expect(titles).to eq(
        [
          "Ascott Sathorn ",
          "Citadines Sukhumvit 8 ",
          "Marvin Suites",
          "Outrigger Laguna Phuket Resort & Villas",
          "Somerset Lake Point "
        ]
      )
    end

    it "sets descriptions for properties" do
      descriptions = properties.map(&:description)

      expectations = [
        %{Ascott Sathorn offers luxurious and spacious apartments complemented with comprehensive services and facilities. The residence is the premier Bangkok serviced apartment property and is ideal for corporate housing.},
        %{Designed for the international professional, the residence is relaxing, spacious and offers hi-tech amenities for modern business and leisure.},
        %{Marvin Suites serviced apartments located in a quiet "Soi" (small street) right off Sathorn road, in the heart of one of Bangkok's prime financial and retail districts. },
        %{Experience stunning residential-style accommodations perfectly suited for elegant living located close to Laguna Phuket Golf Club.  \n\n},
        %{The culture and excitement of Thailand can be enjoyed whilst indulging in the comforts and security of a private serviced residence. These modern and superbly appointed serviced apartments are nestled in a private garden, just minutes from the business district of Silom and Sathorn Road.}
      ]
      expect(descriptions).to eq(expectations)
    end

    it "sets lat and lon for properties" do
      lat_values = properties.map(&:lat)
      lon_values = properties.map(&:lon)

      expect(lat_values).to eq(
        ["13.71702", "13.73693", "13.71762", "8.00382", "13.35908"]
      )
      expect(lon_values).to eq(
        ["100.52724", "100.55612", "100.52692", "98.30736", "100.98747"]
      )
    end

    it "sets city and neighborhood attrs for properties" do
      city_values = properties.map(&:city)
      neighborhood_values = properties.map(&:neighborhood)

      expect(city_values).to eq(
        ["Bangkok", "Bangkok", "Bangkok", "Phuket", "Bangkok"]
      )
      expect(neighborhood_values).to eq(
        ["Sathorn", "Klongtoey", "Sathorn", "Golf Course", "Klongtoey"]
      )
    end

    it "sets country_code for properties" do
      country_codes = properties.map(&:country_code)

      expect(country_codes).to all(eq("US"))
    end

    it "sets currency_code for properties" do
      currency_codes = properties.map(&:currency_code)

      expect(currency_codes).to all(eq("USD"))
    end

    it "sets prices for properties" do
      nightly_rates = properties.map(&:nightly_rate)
      weekly_rates  = properties.map(&:weekly_rate)
      monthly_rates = properties.map(&:monthly_rate)

      expect(nightly_rates).to eq(
        [123.45, 49.94, 99.01, 18.5, 1811.31]
      )
      expect(weekly_rates).to eq(
        [864.15, 349.58, 693.07, 129.5, 12679.17]
      )
      expect(monthly_rates).to eq(
        [3703.5, 1498.2, 2970.3, 555, 54339.3]
      )
    end

    it "sets multi_unit for properties" do
      multi_unit_values = properties.map(&:multi_unit?)

      expect(multi_unit_values).to all(eq(true))
    end

    it "sets on_request for properties" do
      on_request_values = properties.map(&:on_request?)

      expect(on_request_values).to all(eq(false))
    end
  end

  context "when there are on_request properties" do
    before do
      mock_request(:propertysearch, :success_with_on_request)
    end

    let(:result) { subject.call(country) }
    let(:properties) { result.value }

    it "sets on_request for properties" do
      on_request_values = properties.map(&:on_request?)

      expect(on_request_values).to eq([true, false, false, false, false])
    end
  end

  context "when there is only one property in response" do
    before do
      mock_request(:propertysearch, :single)
    end

    it "returns right number of properties" do
      result = subject.call(country)

      expect(result.success?).to be true
      expect(result.value.size).to eq(1)
    end
  end
end
