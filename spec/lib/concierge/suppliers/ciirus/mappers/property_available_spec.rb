require 'spec_helper'

RSpec.describe Ciirus::Mappers::PropertyAvailable do

  let(:result_hash) do
    Concierge::SafeAccessHash.new(
      {
        is_property_available_response: {
          is_property_available_result: false
        }
      }
    )
  end

  let(:available) { described_class.build(result_hash) }

  it 'returns boolean' do
    expect(available).to be false
  end
end
