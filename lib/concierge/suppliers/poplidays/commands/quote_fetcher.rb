module Poplidays
  module Commands
    # +Poplidays::Commands::QuoteFetcher+
    #
    # This class is responsible for performing price quotations for properties coming
    # from Poplidays, parsing the response and building the +Quotation+ object according
    # with the data returned by their API.
    #
    # It uses bookings/easy API endpoint with "requestType":"EVALUATION" parameter.
    # It's better then get all availabilities and search manually.
    #
    # Usage
    #
    #   command = Poplidays::Commands::QuoteFetcher.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value # Array of hashes
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the array of +Hash+.
    class QuoteFetcher < BaseCommand

      PATH = 'bookings/easy'

      def call(params)
        raw_quote = remote_call(params: request_json(params))
        if raw_quote.success?
          json_decode(raw_quote.value)
        else
          raw_quote
        end
      end

      protected

      def path
        PATH
      end

      def authentication
        with_authentication
      end

      def method
        :post
      end

      private

      # Builds cache key
      def key(params)
        [params[:property_id], params[:check_in], params[:check_out]].join('.')
      end

      def mapper
        @mapper ||= Poplidays::Mappers::Quote.new
      end

      def request_json(params)
        {
          'requestType'   => 'EVALUATION', # special type for quote
          'lodgingId'     => params[:property_id],
          'arrival'       => convert_date(params[:check_in]),
          'departure'     => convert_date(params[:check_out]),
          'occupantCount' => params[:guests],
          'customer'      => fake_customer
        }
      end

      def fake_customer
        # All fields are empty for EVALUATION request
        {
          'address'     => {'line1' => '','city' => '','country' => '','postalCode' => ''},
          'email'       => '',
          'firstName'   => '',
          'lastName'    => '',
          'language'    => '',
          'phoneNumber' => ''
        }
      end
    end
  end
end