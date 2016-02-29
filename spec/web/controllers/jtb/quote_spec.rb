require_relative '../../../../apps/web/controllers/jtb/quote'

RSpec.describe Web::Controllers::Jtb::Quote do
  let(:action) { described_class.new }

  describe 'invalid params' do
    let(:params) { Hash[] }

    it 'returns Unprocessable entity status' do
      response = action.call(params)
      expect(response[0]).to eq 422
    end

  end


  describe 'valid params' do
    let(:params) { Hash[property_id: 10, check_in: Date.today, check_out: Date.today + 3, guests_count: 12] }
    it 'is successful' do
      response = action.call(params)
      expect(response[0]).to eq 200
    end
  end

end
