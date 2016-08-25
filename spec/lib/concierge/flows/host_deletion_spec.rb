require 'spec_helper'

RSpec.describe Concierge::Flows::HostDeletion do
  include Support::Factories
  include Support::HTTPStubbing

  let(:host) { create_host }
  let!(:bg_worker) { create_background_worker(host_id: host.id) }

  subject { described_class.new(host) }

  describe '#call' do
    it 'fails with error response from roomorama' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error(:error) }

      subject.call

      expect(HostRepository.find(host.id)).not_to be_nil

      workers = BackgroundWorkerRepository.for_host(host).to_a
      expect(workers).not_to be_empty
    end

    it 'removes host and its workers' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      subject.call

      expect(HostRepository.find(host.id)).to be_nil

      workers = BackgroundWorkerRepository.for_host(host).to_a
      expect(workers).to be_empty
    end

  end
end