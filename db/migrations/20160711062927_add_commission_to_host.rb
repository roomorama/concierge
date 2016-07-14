Hanami::Model.migration do
  change do
    alter_table(:hosts) do
      add_column :commission, Float, null: false, default: 0
    end
  end
end
