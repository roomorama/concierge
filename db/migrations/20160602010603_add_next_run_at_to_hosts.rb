Hanami::Model.migration do
  change do
    alter_table(:hosts) do
      add_column :next_run_at, Time
    end
  end
end
