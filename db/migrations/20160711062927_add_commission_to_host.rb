Hanami::Model.migration do
  change do
    alter_table(:hosts) do
      add_column :commission, Float
    end
  end
end
