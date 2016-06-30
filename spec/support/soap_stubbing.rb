require 'savon/mock/spec_helper'

module Support

  # +Support::SOAPStubbing+
  #
  # SOAP stubbing method helpers for SOAP related specs.
  # The main goal is to encapsulate savon client used under the hood of
  # +API::Support::SOAPClient+ and don't use savon.mock!/unmock! directly
  # in the tests
  #
  module SOAPStubbing
    include Savon::SpecHelper

    def self.included(base)
      base.class_eval do
        before { savon.mock! }
        after { savon.unmock! }
      end
    end

    # Stubs a given SOAP call
    #
    # Example
    #
    #   stub_call(method: :get_properties, response: success_response)
    def stub_call(method:, message: :any, response:)
      savon.expects(method).with(message: message).returns(response)
    end
  end
end
