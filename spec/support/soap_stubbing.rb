require 'savon/mock/spec_helper'

module Support

  # +Support::SOAPStubbing+
  #
  # SOAP stubbing method helpers for SOAP related specs.
  # The main goal is to encapsulate savon client used under the hood of
  # +API::Support::SOAPClient+ and don't use savon.mock!/unmock! directly
  # in the tests.
  # SOAPStubbing also solves the problem with remote call to wsdl file.
  # In tests when you set wsdl option of Savon.client with url, it actual
  # does remote call. To avoid this behavior SOAPStubbing replaces
  # wsdl option with static file, just define wsdl path in your test.
  #
  # Usage
  #
  # RSpec.describe Ciirus::Commands::QuoteFetcher do
  #   include Support::SOAPStubbing
  #
  #   let(:wsdl) { read_fixture('ciirus/wsdl.xml') }
  #   ...
  #   it 'returns success quotation' do
  #     stub_call(method: :get_properties, response: success_response)
  #     result = subject.call(params)
  #
  #     expect(result).to be_a Result
  #   end
  # end

  # end
  module SOAPStubbing
    include Savon::SpecHelper

    def self.included(base)
      base.class_eval do
        before do
          savon.mock!
          # Replace remote call to wsdl with static wsdl
          allow_any_instance_of(Concierge::SOAPClient).to receive(:options).and_wrap_original do |m, *args|
            original = m.call(*args)
            original[:wsdl] = wsdl
            original
          end
        end
        after { savon.unmock! }
      end
    end

    # Stubs a SOAP call to a given method with given message.
    #
    # Example
    #
    #   stub_call(method: :get_properties, message: xml_string, response: stub_response)
    def stub_call(method:, message: :any, response:)
      savon.expects(method).with(message: message).returns(response)
    end
  end
end
