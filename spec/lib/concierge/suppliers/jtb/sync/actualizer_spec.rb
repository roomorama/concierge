require 'spec_helper'

RSpec.describe JTB::Sync::Actualizer do
  let(:credentials) { double(sftp: {}) }

  before do
    allow_any_instance_of(JTB::Sync::DB::BaseActualizer).to receive(:actualize) do
      Result.error(:error)
    end
    allow_any_instance_of(JTB::Sync::FileActualizer).to receive(:cleanup) do
      Result.new(true)
    end
  end

  subject { described_class.new(credentials)}

  describe '#actualize' do

    it 'returns error result if some of file actualizers returns error' do
      allow_any_instance_of(JTB::Sync::DB::HotelsActualizer).to receive(:actualize) do
        Result.new(true)
      end
      file_actualizers_returns = [
        Result.new(true),
        Result.error(:file_error, 'File error')
      ]
      allow_any_instance_of(JTB::Sync::FileActualizer).to receive(:actualize) do
        file_actualizers_returns.shift
      end

      result = subject.actualize

      expect(result).to be_a(Result)
      expect(result.success?).to be false
      expect(result.error.code).to eq(:file_error)
      expect(result.error.data).to eq('File error')
    end

    it 'returns error result if some of DB actualizers fails' do
      db_actualizers_returns = [
        Result.new(true),
        Result.new(true),
        Result.error(:db_error, 'DB error')
      ]
      allow_any_instance_of(JTB::Sync::DB::BaseActualizer).to receive(:actualize) do
        db_actualizers_returns.shift
      end
      allow_any_instance_of(JTB::Sync::FileActualizer).to receive(:actualize) do
        Result.new(true)
      end

      result = subject.actualize

      expect(result).to be_a(Result)
      expect(result.success?).to be false
      expect(result.error.code).to eq(:db_error)
      expect(result.error.data).to eq('DB error')
    end

    it 'returns success result' do
      allow_any_instance_of(JTB::Sync::DB::BaseActualizer).to receive(:actualize) do
        Result.new(true)
      end
      allow_any_instance_of(JTB::Sync::FileActualizer).to receive(:actualize) do
        Result.new(true)
      end

      result = subject.actualize

      expect(result).to be_a(Result)
      expect(result.success?).to be true
    end

    it 'returns success result even if files cleanup fails' do
      allow_any_instance_of(JTB::Sync::DB::BaseActualizer).to receive(:actualize) do
        Result.new(true)
      end
      allow_any_instance_of(JTB::Sync::FileActualizer).to receive(:actualize) do
        Result.new(true)
      end
      allow_any_instance_of(JTB::Sync::FileActualizer).to receive(:cleanup) do
        Result.error(:cleanup_error)
      end

      result = subject.actualize

      expect(result).to be_a(Result)
      expect(result.success?).to be true
    end
  end
end