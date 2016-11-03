require 'spec_helper'

RSpec.describe JTB::Sync::DB::RatePlansActualizer do
  let(:rate_plan_attributes) do
    {
      city_code: "CHU",
      hotel_code: "W01",
      rate_plan_id: "CHUHW0101STD1DBL",
      room_code: "CHUHW01RMZ000003",
      meal_plan_code: "RMO",
      occupancy: 1,
   }
  end

  subject { described_class.new(tmp_path)}

  describe '#actualize' do
    context 'when exception during actualize' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'rate_plans', 'with_all') }

      it 'returns error with description' do
        allow_any_instance_of(described_class).to receive(:import_file) do
          raise StandardError.new('Some error')
        end

        result = subject.actualize
        expect(result.success?).to be false
        expect(result.error.code).to eq(:jtb_db_actualization_error)
        expect(result.error.data).to eq('Error during import file with prefix `RoomPlan` to DB. Some error')
      end
    end

    context 'when diff file is empty' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'rate_plans', 'empty_diff') }

      it 'does nothing' do
        create_rate_plan(rate_plan_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        rate_plans = JTB::Repositories::RatePlanRepository.all
        expect(rate_plans.length).to eq(1)
      end
    end

    context 'when diff file contains create update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'rate_plans', 'create') }

      it 'creates new rate plan and ignores not english diff' do
        rate_plan = JTB::Repositories::RatePlanRepository.by_primary_key('CHU', 'W01', 'CHUHW0101STD1DBL')
        expect(rate_plan).to be_nil

        result = subject.actualize
        expect(result.success?).to be true

        rate_plans = JTB::Repositories::RatePlanRepository.all
        expect(rate_plans.length).to eq(1)

        rate_plan = JTB::Repositories::RatePlanRepository.by_primary_key('CHU', 'W01', 'CHUHW0101STD1DBL')
        expect(rate_plan).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomPlan')
        expect(state.file_name).to eq('RoomPlan_Diff_20161010013224.zip')
      end
    end

    context 'when diff file contains update update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'rate_plans', 'update') }

      it 'updates rate plan' do
        create_rate_plan(rate_plan_attributes)
        create_rate_plan(rate_plan_attributes.merge({ hotel_code: 'W03', occupancy: 10 }))

        result = subject.actualize
        expect(result.success?).to be true

        # Update rate_plan
        rate_plan = JTB::Repositories::RatePlanRepository.by_primary_key('CHU', 'W01', 'CHUHW0101STD1DBL')
        expect(rate_plan.occupancy).to eq('2')

        # Does not update another rate_plan
        rate_plan = JTB::Repositories::RatePlanRepository.by_primary_key('CHU', 'W03', 'CHUHW0101STD1DBL')
        expect(rate_plan.occupancy).to eq('10')

        state = JTB::Repositories::StateRepository.by_prefix('RoomPlan')
        expect(state.file_name).to eq('RoomPlan_Diff_20161010013225.zip')
      end
    end

    context 'when directory contains ALL file' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'rate_plans', 'with_all') }

      it 'imports the rate plans from the file and filters out not english' do
        result = subject.actualize
        expect(result.success?).to be true

        rate_plans = JTB::Repositories::RatePlanRepository.all
        expect(rate_plans.length).to eq(6)

        state = JTB::Repositories::StateRepository.by_prefix('RoomPlan')
        expect(state.file_name).to eq('RoomPlan_ALL_20161010.zip')
      end

      it 'clear table before actualisation' do
        create_rate_plan(rate_plan_attributes.merge({ rate_plan_id: 'QQQQQQ', city_code: 'QQQ', hotel_code: 'QQQ' }))

        result = subject.actualize
        expect(result.success?).to be true

        rate_plan = JTB::Repositories::RatePlanRepository.by_primary_key('QQQ', 'QQQ', 'QQQQQQ')
        expect(rate_plan).to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomPlan')
        expect(state.file_name).to eq('RoomPlan_ALL_20161010.zip')
      end
    end

    context 'when diff file contains delete update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'rate_plans', 'delete') }

      it 'delete the rate plan' do
        create_rate_plan(rate_plan_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        rate_plans = JTB::Repositories::RatePlanRepository.all
        expect(rate_plans.length).to eq(0)

        state = JTB::Repositories::StateRepository.by_prefix('RoomPlan')
        expect(state.file_name).to eq('RoomPlan_Diff_20161010013226.zip')
      end
    end

    context 'when there is some problem during some file actualization' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'rate_plans', 'transaction') }

      it 'imports only files before invalid' do
        result = subject.actualize
        expect(result.success?).to be false

        rate_plans = JTB::Repositories::RatePlanRepository.all
        expect(rate_plans.length).to eq(1)

        rate_plan = JTB::Repositories::RatePlanRepository.by_primary_key('CHU', 'W01', 'CHUHW0101STD1DBL')
        expect(rate_plan).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('RoomPlan')
        expect(state.file_name).to eq('RoomPlan_Diff_20161010013227.zip')
      end
    end

    context 'when directory contains ALL and Diff files' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'rate_plans', 'all_and_diff') }

      it 'imports all data' do
        result = subject.actualize
        expect(result.success?).to be true

        rate_plans = JTB::Repositories::RatePlanRepository.all
        expect(rate_plans.length).to eq(6)

        rate_plan = JTB::Repositories::RatePlanRepository.by_primary_key('CHU', 'W01', 'CHUHW0101STD1DBL')
        expect(rate_plan.occupancy).to eq('2')

        state = JTB::Repositories::StateRepository.by_prefix('RoomPlan')
        expect(state.file_name).to eq('RoomPlan_Diff_20161010013225.zip')
      end
    end

    def create_rate_plan(attributes)
      JTB::Repositories::RatePlanRepository.create(
        JTB::Entities::RatePlan.new(attributes)
      )
    end
  end
end