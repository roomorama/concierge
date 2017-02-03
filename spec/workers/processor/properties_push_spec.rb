require "spec_helper"

RSpec.describe Workers::Processor::PropertiesPush do
  include Support::Factories

  let!(:properties) { 2.times.collect {|i| create_property(identifier: i) } }

  subject { described_class.new(properties.collect(&:id)) }

  it 'creates external error for each failed Roomorama op' do
    allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error(:http_status_500) }
    expect { subject.run }.to change { ExternalErrorRepository.count }.by 2
    expect(ExternalErrorRepository.last.supplier).to eq 'roomorama'
  end
end
