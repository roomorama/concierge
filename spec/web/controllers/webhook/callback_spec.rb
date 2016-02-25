require_relative '../../../../apps/web/controllers/webhook/callback'

RSpec.describe Web::Controllers::Webhook::Callback do
  let(:action) { described_class.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    expect(response[0]).to eq 200
  end
end
