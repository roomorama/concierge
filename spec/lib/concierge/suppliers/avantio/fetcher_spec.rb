require 'spec_helper'

RSpec.describe Avantio::Fetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:code_partner) { '7a9f4n99' }
  let(:endpoint) { "http://feeds.avantio.com/accommodations/#{code_partner}" }

  subject { described_class.new(code_partner) }

  it 'returns the underlying network error if any happened' do
    stub_call(:get, endpoint) { raise Faraday::TimeoutError }
    result = subject.fetch('accommodations')

    expect(result).not_to be_success
    expect(result.error.code).to eq :connection_timeout
  end

  it 'returns success for valid xml' do
    stub_call(:get, endpoint) { [200, {}, read_fixture('avantio/valid.zip')] }
    result = subject.fetch('accommodations')

    expect(result).to be_success
    expect(result.value).to be_a(Nokogiri::XML::Document)
  end

  it 'returns error for invalid xml' do
    stub_call(:get, endpoint) { [200, {}, read_fixture('avantio/invalid.zip')] }
    result = subject.fetch('accommodations')

    expect(result).not_to be_success
    expect(result.error.code).to eq(:xml_syntax_error)
  end

  it 'returns error for unknown code' do
    result = subject.fetch('foo')

    expect(result).not_to be_success
    expect(result.error.code).to eq(:unknown_code)
  end
end