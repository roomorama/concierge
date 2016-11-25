require "spec_helper"

RSpec.describe OverwriteRepository do
  include Support::Factories

  describe ".data" do
    it { expect(create_overwrite.data).to be_a Concierge::SafeAccessHash }
  end
end
