require 'spec_helper'

module SAW
  RSpec.describe Converters::CountryCode do
    it "overrides country name if needed" do
      code = described_class.code_by_name("Korea, Republic of")
      expect(code).to eq("KR")
    end

    it "uses original name if there is no custom name" do
      code = described_class.code_by_name("Kuwait")
      expect(code).to eq("KW")
    end
  end
end
