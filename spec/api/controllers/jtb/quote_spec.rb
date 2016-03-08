require "spec_helper"
require_relative "../shared/quote_validations"

RSpec.describe API::Controllers::JTB::Quote do

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new }

end
