Hanami::Model.migration do
  change do
    alter_table(:external_errors) do
      add_column :environment, :hstore, null: false
    end
  end
end
