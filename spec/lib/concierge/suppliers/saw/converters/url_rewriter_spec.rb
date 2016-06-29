require 'spec_helper'

module SAW
  RSpec.describe Converters::URLRewriter do
    let(:staging_url) do
      'http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39907'
    end

    let(:expected_url) do
      'http://www.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=39907'
    end

    it "converts SAW image URL from staging-format to production-one" do
      result_url = described_class.build(staging_url)
      expect(result_url).to eq(expected_url)
    end
  end
end
