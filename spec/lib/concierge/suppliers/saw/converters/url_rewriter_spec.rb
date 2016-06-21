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
      result_url = described_class.build(staging_url, rewrite: true)
      expect(result_url).to eq(expected_url)
    end

    it "doesn't perform convertion if mode is not staging" do
      result_url = described_class.build(staging_url, rewrite: false)
      expect(result_url).to eq(staging_url)
    end
  end
end
