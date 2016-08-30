Hanami::Model.migration do
  change do
    alter_table :background_workers do
      add_column :next_run_args, JSON, null: false, default: Sequel.pg_json({})
    end
  end
end
