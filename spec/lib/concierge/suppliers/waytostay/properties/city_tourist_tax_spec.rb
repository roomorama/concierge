require 'spec_helper'

RSpec.describe Waytostay::Properties::CityTouristTax do
  it "should parse" do
    expect { described_class.new(nil).parse }.to_not raise_error
  end
end
