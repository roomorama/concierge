require 'spec_helper'

module Woori
  RSpec.describe Converters::CountryCode do
    let(:converter) { described_class.new }

    it "overrides country name if needed" do
      code = converter.code_by_name("Korea, Republic of")
      expect(code).to eq("KR")
    end

    it "uses original name if there is no custom name" do
      code = converter.code_by_name("Kuwait")
      expect(code).to eq("KW")
    end
  end
end
