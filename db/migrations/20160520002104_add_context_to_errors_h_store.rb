Hanami::Model.migration do
  change do
    alter_table(:external_errors) do
      add_column :context, :hstore, null: false, default: Sequel.hstore({})
    end
  end
end
