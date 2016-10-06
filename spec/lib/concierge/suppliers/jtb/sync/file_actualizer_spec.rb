require 'spec_helper'

RSpec.describe JTB::Sync::FileActualizer do
  let(:sftp_mock) { double('sftp') }
  let(:file_prefix) { 'RoomStock' }
  let(:credentials) { double(sftp: {}) }

  before do
    allow_any_instance_of(described_class).to receive(:sftp) { sftp_mock }
    allow(File).to receive(:exists?) { true }
    allow_any_instance_of(described_class).to receive(:cleanup) { true }
  end

  subject { described_class.new(credentials, file_prefix)}

  describe '#actualize' do
    context 'when first sync' do
      let(:last_synced) { nil }

      it 'downloads the last ALL file and diffs after him' do
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', '**/RoomStock_ALL_*').and_return(
          [
            double(name: 'RoomStock_ALL_20160922.zip'),
            double(name: 'old/RoomStock_ALL_20160921.zip'),
            double(name: 'old/RoomStock_ALL_20160920.zip'),
          ]
        )
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', '**/RoomStock_Diff_*').and_return(
          [
            double(name: 'RoomStock_Diff_20160922051813.zip'),
            double(name: 'old/RoomStock_Diff_20160921051813.zip'),
            double(name: 'old/RoomStock_Diff_20160920051813.zip'),
          ]
        )

        expect(subject).to receive(:fetch_file).with('RoomStock_ALL_20160922.zip').ordered.and_return true
        expect(subject).to receive(:fetch_file).with('RoomStock_Diff_20160922051813.zip').ordered.and_return true

        result = subject.actualize(last_synced)
        expect(result.success?).to be true
      end

      it 'returns error when the last ALL file not found' do
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', '**/RoomStock_ALL_*').and_return([])

        result = subject.actualize(last_synced)

        expect(result.success?).to be false
        expect(result.error.code).to be :all_file_not_found
      end
    end

    context 'when last sync was too long ago' do
      let(:last_synced) { 'RoomStock_ALL_20160919.zip' }

      it 'returns the last ALL file and diffs after him' do
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', '**/RoomStock_ALL_*').and_return(
          [
            double(name: 'RoomStock_ALL_20160922.zip'),
            double(name: 'old/RoomStock_ALL_20160921.zip'),
            double(name: 'old/RoomStock_ALL_20160920.zip'),
          ]
        )
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', '**/RoomStock_Diff_*').and_return(
          [
            double(name: 'RoomStock_Diff_20160922051813.zip'),
            double(name: 'old/RoomStock_Diff_20160921051813.zip'),
            double(name: 'old/RoomStock_Diff_20160920051813.zip'),
          ]
        )
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', "**/#{last_synced}").and_return([])

        expect(subject).to receive(:fetch_file).with('RoomStock_ALL_20160922.zip').ordered.and_return true
        expect(subject).to receive(:fetch_file).with('RoomStock_Diff_20160922051813.zip').ordered.and_return true

        result = subject.actualize(last_synced)
        expect(result.success?).to be true
      end

      it 'returns error when the last ALL file not found' do
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', '**/RoomStock_ALL_*').and_return([])
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', "**/#{last_synced}").and_return([])

        result = subject.actualize(last_synced)

        expect(result.success?).to be false
        expect(result.error.code).to be :all_file_not_found
      end
    end

    context 'when last sync was not so long ago' do
      let(:last_synced) { 'RoomStock_Diff_20160921051813.zip' }
      it 'downloads diffs after him' do
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', '**/RoomStock_Diff_*').and_return(
          [
            double(name: 'RoomStock_Diff_20160922051813.zip'),
            double(name: 'old/RoomStock_Diff_20160921051914.zip'),
            double(name: 'old/RoomStock_Diff_20160921051813.zip'),
            double(name: 'old/RoomStock_Diff_20160920051813.zip'),
          ]
        )
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', "**/#{last_synced}").and_return(
          [double(name: 'old/RoomStock_Diff_20160921051813.zip')]
        )

        expect(subject).to receive(:fetch_file).with('RoomStock_Diff_20160922051813.zip').ordered.and_return true
        expect(subject).to receive(:fetch_file).with('old/RoomStock_Diff_20160921051914.zip').ordered.and_return true

        result = subject.actualize(last_synced)
        expect(result.success?).to be true
      end
    end

    context 'when force_all is true' do
      let(:last_synced) { 'RoomStock_ALL_20160919.zip' }

      it 'downloads files from last ALL file' do
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', '**/RoomStock_ALL_*').and_return(
          [
            double(name: 'RoomStock_ALL_20160922.zip'),
            double(name: 'old/RoomStock_ALL_20160921.zip'),
            double(name: 'old/RoomStock_ALL_20160920.zip'),
            double(name: 'old/RoomStock_ALL_20160919.zip'),
          ]
        )
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', '**/RoomStock_Diff_*').and_return(
          [
            double(name: 'RoomStock_Diff_20160922051813.zip'),
            double(name: 'old/RoomStock_Diff_20160921051813.zip'),
            double(name: 'old/RoomStock_Diff_20160920051813.zip'),
          ]
        )
        allow(sftp_mock).to receive_message_chain(:dir, :glob).with('./', "**/#{last_synced}").and_return(
          [double(name: 'old/RoomStock_ALL_20160919.zip')]
        )

        expect(subject).to receive(:fetch_file).with('RoomStock_ALL_20160922.zip').ordered.and_return true
        expect(subject).to receive(:fetch_file).with('RoomStock_Diff_20160922051813.zip').ordered.and_return true

        result = subject.actualize(last_synced, true)
        expect(result.success?).to be true
      end
    end
  end
end