require_relative "../quote"

module API::Controllers::JTB

  # API::Controllers::JTB::Quote
  #
  # Performs booking quotations for properties from JTB.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      credentials = Credentials.for("jtb")
      JTB::Client.new(credentials).quote(params)
    end

  end
end
