Hanami::Model.migration do
  change do
    alter_table(:hosts) do
      add_column :cancellation_policy, String
    end
  end
end
