require 'spec_helper'

RSpec.describe JTB::Sync::DB::LookupsActualizer do
  let(:lookup_attributes) do
    {
      language: 'EN',
      category: '1',
      id: '01',
      related_id: nil,
      name: 'Hokkaido (Sapporo / Chitose)'
    }
  end

  subject { described_class.new(tmp_path)}

  describe '#actualize' do
    context 'when exception during actualize' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'lookups', 'with_all') }

      it 'returns error with description' do
        allow_any_instance_of(described_class).to receive(:import_file) do
          raise Exception.new
        end

        result = subject.actualize
        expect(result.success?).to be false
        expect(result.error.data).to eq('Error during import file with prefix `GenericMaster` to DB')
      end
    end

    context 'when diff file presented' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'lookups', 'with_diff') }

      it 'returns unsuccess result' do
        expect { subject.actualize }.to raise_exception(NotImplementedError)
      end
    end

    context 'when directory contains ALL file' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'lookups', 'with_all') }

      it 'imports the lookups from the file' do
        result = subject.actualize
        expect(result.success?).to be true

        lookups = JTB::Repositories::LookupRepository.all
        expect(lookups.length).to eq(5)

        state = JTB::Repositories::StateRepository.by_prefix('GenericMaster')
        expect(state.file_name).to eq('GenericMaster_ALL_20161010.zip')
      end

      it 'clear table before actualisation' do
        create_lookup(lookup_attributes.merge({ language: 'QQ', category: 'QQ', id: 'QQQ' }))

        result = subject.actualize
        expect(result.success?).to be true

        lookup = JTB::Repositories::LookupRepository.by_primary_key('QQ', 'QQQ', 'QQQ')
        expect(lookup).to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('GenericMaster')
        expect(state.file_name).to eq('GenericMaster_ALL_20161010.zip')
      end
    end

    def create_lookup(attributes)
      JTB::Repositories::LookupRepository.create(
        JTB::Entities::Lookup.new(attributes)
      )
    end
  end
end