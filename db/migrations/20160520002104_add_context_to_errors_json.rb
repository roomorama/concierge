Hanami::Model.migration do
  change do
    alter_table(:external_errors) do
      add_column :context, :json, null: false, default: Sequel.pg_json({})
    end
  end
end
