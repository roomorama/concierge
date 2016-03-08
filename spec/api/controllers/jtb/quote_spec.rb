require "spec_helper"
require_relative "../shared/multi_unit_quote_validations"

RSpec.describe API::Controllers::JTB::Quote do

  it_behaves_like "performing multi unit parameter validations", controller_generator: -> { described_class.new }

end
