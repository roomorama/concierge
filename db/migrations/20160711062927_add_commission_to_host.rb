Hanami::Model.migration do
  change do
    alter_table(:hosts) do
      add_column :fee_percentage, Float, null: false
    end
  end
end
