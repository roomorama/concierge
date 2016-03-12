module API::Controllers::Params

  # +API::Controllers::Params::Booking
  #
  # Parameters declaration and validation for create booking. This is
  # shared among all partner booking calls, and ensures that required parameters
  # are present and in an acceptable format.
  #
  # If the parameters given are not valid, booking controllers that include this
  # module will return a 422 HTTP status, with a response payload that reports
  # the errors in the parameters.
  class Booking < API::Action::Params

    DATE_FORMAT = /\d\d\d-\d\d-\d\d/

    param :property_id, presence: true, type: String
    param :check_in,    presence: true, type: String, format: DATE_FORMAT
    param :check_out,   presence: true, type: String, format: DATE_FORMAT
    param :guests,      presence: true, type: Integer
    
    param :extra
    param :customer do
      param :first_name,  type: String, presence: true
      param :last_name,   type: String, presence: true
      param :country,     type: String, presence: true
      param :city,        type: String, presence: true
      param :address,     type: String, presence: true
      param :postal_code, type: String, presence: true
      param :email,       type: String, presence: true
      param :phone,       type: String, presence: true
      param :language,    type: String
      param :gender,      type: String
    end

    def error_messages
      ErrorMessages.new(errors).generate
    end
  end

end
