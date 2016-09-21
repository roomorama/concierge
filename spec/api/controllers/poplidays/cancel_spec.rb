require 'spec_helper'
require_relative "../shared/cancel"

RSpec.describe API::Controllers::Poplidays::Cancel do
  it_behaves_like "Zendesk cancellation notification", supplier: "Poplidays"
end
