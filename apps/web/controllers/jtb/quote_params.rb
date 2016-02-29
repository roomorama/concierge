module Web::Controllers::Jtb
  class QuoteParams < Web::Action::Params

    param :property_id , presence: true
    param :check_in, presence: true
    param :check_out, presence: true
    param :guests_count, presence: true, type: Integer, size: 1..10

  end
end
