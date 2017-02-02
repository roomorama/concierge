require 'spec_helper'

RSpec.describe Concierge::Flows::PropertyPush do
  include Support::Factories

  let(:host) { create_host }
  let!(:bg_worker) { create_background_worker(host_id: host.id) }
  let!(:sync_process) { create_sync_process(host_id: host.id) }
  let!(:properties) { 4.times.collect {|i| create_property(identifier: i, host_id: host.id) } }

  subject { described_class.new(host) }

  describe '#call' do
    it 'sends roomorama publish operation for each property' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new() }
      expect(subject.call).to all(be_success)
    end

    it 'fails with error response from roomorama' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error(:error) }

      results = subject.call

      results.each do |r|
        expect(r).not_to be_success
      end
    end
  end
end
