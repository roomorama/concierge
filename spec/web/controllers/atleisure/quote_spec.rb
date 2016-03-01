require "spec_helper"
require_relative "../shared/quote_validations"

RSpec.describe Web::Controllers::AtLeisure::Quote do

  it_behaves_like "performing parameter validations", action: described_class.new

end
