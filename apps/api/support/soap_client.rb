module API::Support
  class SOAPClient

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def call(*args)
      with_error_handling do |cli|
        cli.call(*args)
      end
    end

    def client
      Savon.client(options)
    end

    private

    def with_error_handling
      response = yield(client)

      Result.new(response)

    rescue Savon::HTTPError => err
      Result.error("http_status_#{err.http.code}", err.message)
    rescue Savon::SOAPFault => err
      Result.error(:soap_fault, err.message)
    rescue Savon::InvalidResponseError => err
      Result.error(:invalid_response, err.message)
    rescue Savon::UnknownOperationError => err
      Result.error(:unknown_operation, err.message)
    end

  end
end